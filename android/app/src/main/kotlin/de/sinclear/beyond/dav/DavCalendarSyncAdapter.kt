package de.sinclear.beyond.dav

import android.accounts.Account
import android.accounts.AccountManager
import android.content.AbstractThreadedSyncAdapter
import android.content.ContentProviderClient
import android.content.ContentProviderOperation
import android.content.ContentValues
import android.content.Context
import android.content.SyncResult
import android.os.Bundle
import android.provider.CalendarContract
import android.util.Base64
import android.util.Log
import android.util.Xml
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.xmlpull.v1.XmlPullParser
import java.io.IOException
import java.io.StringReader
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone

/**
 * Synchronisiert die drei Beyond-Kalender (Events, Reisen & Fahrten,
 * Geburtstage) einseitig (read-only API) in die Android-Systemkalenderdatenbank:
 * je Kalender einen `REPORT calendar-query` an den DAV-Endpunkt senden, die
 * VEVENTs parsen und per UID diffen (insert/update/delete).
 */
class DavCalendarSyncAdapter(
    context: Context,
    autoInitialize: Boolean,
) : AbstractThreadedSyncAdapter(context, autoInitialize) {

    private enum class FetchStatus { OK, AUTH, HTTP, IO }

    private data class FetchResult(val status: FetchStatus, val body: String?, val code: Int? = null)

    override fun onPerformSync(
        account: Account,
        extras: Bundle,
        authority: String,
        provider: ContentProviderClient,
        syncResult: SyncResult,
    ) {
        val am = AccountManager.get(context)
        val userId = am.getUserData(account, DavConstants.KEY_USER_ID) ?: run {
            Log.e(TAG, "Kein userId im Account")
            setUserData(am, account, DavConstants.KEY_LAST_ERROR, "config")
            return
        }
        val davBaseUrl = am.getUserData(account, DavConstants.KEY_DAV_BASE_URL) ?: run {
            Log.e(TAG, "Kein davBaseUrl im Account")
            setUserData(am, account, DavConstants.KEY_LAST_ERROR, "config")
            return
        }
        val token = am.getUserData(account, DavConstants.KEY_DAV_TOKEN) ?: run {
            Log.e(TAG, "Kein davToken im Account")
            setUserData(am, account, DavConstants.KEY_LAST_ERROR, "config")
            return
        }
        val enabled = am.getUserData(account, DavConstants.KEY_ENABLED_SEGMENTS)
            ?.split(',')
            ?.filter { it.isNotBlank() }
            ?.toSet()
            ?: DavConstants.CALENDARS.map { it.segment }.toSet()

        for (kind in DavConstants.CALENDARS) {
            if (kind.segment !in enabled) {
                deleteCalendar(account, kind)
                continue
            }
            if (syncCalendar(account, am, userId, davBaseUrl, token, kind, syncResult)) {
                // Auth- oder Netz-Fehler: nicht weiter mit weiteren Kalendern.
                return
            }
        }

        setUserData(am, account, DavConstants.KEY_LAST_ERROR, null)
        setUserData(am, account, DavConstants.KEY_LAST_SYNC, System.currentTimeMillis().toString())
    }

    /** Synchronisiert einen Kalender. Liefert `true`, wenn der Sync abgebrochen
     *  werden soll (Auth-/Netzfehler), sonst `false`. */
    private fun syncCalendar(
        account: Account,
        am: AccountManager,
        userId: String,
        davBaseUrl: String,
        token: String,
        kind: CalendarKind,
        syncResult: SyncResult,
    ): Boolean {
        val url = davBaseUrl.trimEnd('/') + "/calendars/$userId/${kind.segment}/"
        val fetch = fetchCalendarQuery(url, account.name, token)

        when (fetch.status) {
            FetchStatus.AUTH -> {
                Log.e(TAG, "Auth-Fehler (401/403) für ${kind.segment}")
                syncResult.stats.numAuthExceptions++
                setUserData(am, account, DavConstants.KEY_LAST_ERROR, "auth")
                return true
            }
            FetchStatus.HTTP, FetchStatus.IO -> {
                Log.e(TAG, "Fetch-Fehler für ${kind.segment}: ${fetch.status} ${fetch.code}")
                syncResult.stats.numIoExceptions++
                syncResult.delayUntil = 300
                val label = if (fetch.status == FetchStatus.HTTP) {
                    "error:HTTP:${fetch.code}"
                } else {
                    "error:IO"
                }
                setUserData(am, account, DavConstants.KEY_LAST_ERROR, label)
                return true
            }
            FetchStatus.OK -> Unit
        }

        val events = parseMultistatus(fetch.body.orEmpty())
        val calId = try {
            ensureCalendar(account, kind)
        } catch (e: Exception) {
            Log.e(TAG, "ensureCalendar-Fehler für ${kind.segment}", e)
            null
        }
        if (calId == null) {
            Log.e(TAG, "Kalender ${kind.segment} konnte nicht angelegt werden")
            syncResult.stats.numIoExceptions++
            setUserData(am, account, DavConstants.KEY_LAST_ERROR, "calendar")
            return true
        }

        try {
            val ops = buildOperations(account, calId, events)
            if (ops.isNotEmpty()) {
                context.contentResolver.applyBatch(CalendarContract.AUTHORITY, ops)
            }
        } catch (e: Exception) {
            Log.e(TAG, "applyBatch-Fehler für ${kind.segment}", e)
            syncResult.stats.numIoExceptions++
            setUserData(am, account, DavConstants.KEY_LAST_ERROR, "apply")
            return true
        }
        return false
    }

    /** Entfernt einen abgewählten Kalender samt seiner Events aus dem System. */
    private fun deleteCalendar(account: Account, kind: CalendarKind) {
        val uri = DavSyncManager.syncUri(CalendarContract.Calendars.CONTENT_URI, account)
        val selection = "${CalendarContract.Calendars.ACCOUNT_NAME} = ? AND " +
            "${CalendarContract.Calendars.ACCOUNT_TYPE} = ? AND " +
            "${CalendarContract.Calendars.NAME} = ?"
        val args = arrayOf(account.name, DavConstants.ACCOUNT_TYPE, kind.name)
        context.contentResolver.delete(uri, selection, args)
    }

    private fun fetchCalendarQuery(url: String, email: String, token: String): FetchResult {
        val start = System.currentTimeMillis() - YEAR_MILLIS
        val end = System.currentTimeMillis() + 2 * YEAR_MILLIS
        val body = calendarQueryBody(start, end)

        val request = Request.Builder()
            .url(url)
            .method(
                "REPORT",
                body.toRequestBody("application/xml; charset=utf-8".toMediaType()),
            )
            .header("Depth", "1")
            .header("Authorization", basicAuth(email, token))
            .build()

        return try {
            client.newCall(request).execute().use { response ->
                val code = response.code
                when {
                    code == 207 -> FetchResult(
                        FetchStatus.OK,
                        response.body?.string().orEmpty(),
                    )
                    code == 401 || code == 403 -> FetchResult(FetchStatus.AUTH, null)
                    else -> {
                        Log.e(TAG, "REPORT-Status: $code")
                        FetchResult(FetchStatus.HTTP, null, code)
                    }
                }
            }
        } catch (e: IOException) {
            Log.e(TAG, "REPORT-Fehler", e)
            FetchResult(FetchStatus.IO, null)
        }
    }

    /** Baut einen `REPORT calendar-query` mit `time-range` im VTIMEZONE-freien
     *  UTC-Fenster. sabre/dav liefert darauf die VEVENTs als Multistatus. */
    private fun calendarQueryBody(startMillis: Long, endMillis: Long): String {
        val s = icsTimestamp(startMillis)
        val e = icsTimestamp(endMillis)
        return "<?xml version=\"1.0\" encoding=\"utf-8\" ?>" +
            "<C:calendar-query xmlns:D=\"DAV:\" xmlns:C=\"urn:ietf:params:xml:ns:caldav\">" +
            "<D:prop><D:getetag/><C:calendar-data/></D:prop>" +
            "<C:filter><C:comp-filter name=\"VCALENDAR\">" +
            "<C:comp-filter name=\"VEVENT\">" +
            "<C:time-range start=\"$s\" end=\"$e\"/>" +
            "</C:comp-filter></C:comp-filter></C:filter>" +
            "</C:calendar-query>"
    }

    private fun icsTimestamp(millis: Long): String {
        val fmt = SimpleDateFormat("yyyyMMdd'T'HHmmss'Z'", Locale.US).apply {
            timeZone = TimeZone.getTimeZone("UTC")
        }
        return fmt.format(Date(millis))
    }

    /** Extrahiert die `<calendar-data>`-Blöcke aus der Multistatus-Antwort und
     *  parst jedes enthaltene VCALENDAR. sabre/dav liefert die ICS-Daten in
     *  CDATA; der XmlPullParser liefert den Text bereits entschachtelt. */
    private fun parseMultistatus(xml: String): List<DavEvent> {
        val events = mutableListOf<DavEvent>()
        val parser = Xml.newPullParser()
        parser.setFeature(XmlPullParser.FEATURE_PROCESS_NAMESPACES, true)
        parser.setInput(StringReader(xml))
        var eventType = parser.eventType
        while (eventType != XmlPullParser.END_DOCUMENT) {
            if (eventType == XmlPullParser.START_TAG &&
                parser.name == "calendar-data"
            ) {
                val ics = parser.nextText()
                events += IcsParser.parse(ics)
            }
            eventType = parser.next()
        }
        return events
    }

    private fun ensureCalendar(account: Account, kind: CalendarKind): Long? {
        val uri = DavSyncManager.syncUri(CalendarContract.Calendars.CONTENT_URI, account)
        val projection = arrayOf(CalendarContract.Calendars._ID)
        val selection = "${CalendarContract.Calendars.ACCOUNT_NAME} = ? AND " +
            "${CalendarContract.Calendars.ACCOUNT_TYPE} = ? AND " +
            "${CalendarContract.Calendars.NAME} = ?"
        val args = arrayOf(account.name, DavConstants.ACCOUNT_TYPE, kind.name)
        context.contentResolver.query(uri, projection, selection, args, null)?.use { cursor ->
            if (cursor.moveToFirst()) {
                val calId = cursor.getLong(0)
                updateCalendarColor(uri, calId, kind)
                return calId
            }
        }

        val values = ContentValues().apply {
            put(CalendarContract.Calendars.ACCOUNT_NAME, account.name)
            put(CalendarContract.Calendars.ACCOUNT_TYPE, DavConstants.ACCOUNT_TYPE)
            put(CalendarContract.Calendars.NAME, kind.name)
            put(CalendarContract.Calendars.CALENDAR_DISPLAY_NAME, kind.displayName)
            put(CalendarContract.Calendars.CALENDAR_ACCESS_LEVEL, CalendarContract.Calendars.CAL_ACCESS_READ)
            put(CalendarContract.Calendars.VISIBLE, 1)
            put(CalendarContract.Calendars.SYNC_EVENTS, 1)
            put(CalendarContract.Calendars.OWNER_ACCOUNT, account.name)
            put(CalendarContract.Calendars.CALENDAR_COLOR, kind.color)
        }
        val inserted = context.contentResolver.insert(uri, values)
        return inserted?.lastPathSegment?.toLongOrNull()
    }

    /** Hält die Farbe eines bestehenden Kalenders aktuell (API kann sie ändern). */
    private fun updateCalendarColor(uri: android.net.Uri, calId: Long, kind: CalendarKind) {
        val values = ContentValues().apply {
            put(CalendarContract.Calendars.CALENDAR_DISPLAY_NAME, kind.displayName)
            put(CalendarContract.Calendars.CALENDAR_COLOR, kind.color)
            put(CalendarContract.Calendars.VISIBLE, 1)
            put(CalendarContract.Calendars.SYNC_EVENTS, 1)
        }
        context.contentResolver.update(
            uri,
            values,
            "${CalendarContract.Calendars._ID} = ?",
            arrayOf(calId.toString()),
        )
    }

    private fun buildOperations(
        account: Account,
        calId: Long,
        remote: List<DavEvent>,
    ): ArrayList<ContentProviderOperation> {
        val eventUri = DavSyncManager.syncUri(CalendarContract.Events.CONTENT_URI, account)

        val local = mutableMapOf<String, Long>()
        val projection = arrayOf(CalendarContract.Events._ID, CalendarContract.Events.UID_2445)
        context.contentResolver.query(
            eventUri,
            projection,
            "${CalendarContract.Events.CALENDAR_ID} = ?",
            arrayOf(calId.toString()),
            null,
        )?.use { cursor ->
            val idCol = cursor.getColumnIndexOrThrow(CalendarContract.Events._ID)
            val uidCol = cursor.getColumnIndexOrThrow(CalendarContract.Events.UID_2445)
            while (cursor.moveToNext()) {
                val uid = cursor.getString(uidCol) ?: continue
                local[uid] = cursor.getLong(idCol)
            }
        }

        val ops = ArrayList<ContentProviderOperation>()
        for (event in remote) {
            val localId = local.remove(event.uid)
            val builder = if (localId != null) {
                ContentProviderOperation.newUpdate(eventUri)
                    .withSelection("${CalendarContract.Events._ID} = ?", arrayOf(localId.toString()))
            } else {
                ContentProviderOperation.newInsert(eventUri)
                    .withValue(CalendarContract.Events.CALENDAR_ID, calId)
                    .withValue(CalendarContract.Events.UID_2445, event.uid)
                    .withValue(CalendarContract.Events.EVENT_TIMEZONE, "UTC")
            }
            builder
                .withValue(CalendarContract.Events.TITLE, event.title ?: "")
                .withValue(CalendarContract.Events.DESCRIPTION, event.description ?: "")
                .withValue(CalendarContract.Events.EVENT_LOCATION, event.location ?: "")
                .withValue(CalendarContract.Events.DTSTART, event.startMillis)
                .withValue(CalendarContract.Events.DTEND, event.endMillis)
                .withValue(CalendarContract.Events.DIRTY, 0)
                .build()
                .let(ops::add)
        }

        for (id in local.values) {
            ops += ContentProviderOperation.newDelete(eventUri)
                .withSelection("${CalendarContract.Events._ID} = ?", arrayOf(id.toString()))
                .build()
        }
        return ops
    }

    private fun basicAuth(email: String, token: String): String =
        "Basic " + Base64.encodeToString("$email:$token".toByteArray(Charsets.UTF_8), Base64.NO_WRAP)

    private fun setUserData(am: AccountManager, account: Account, key: String, value: String?) {
        am.setUserData(account, key, value)
    }

    companion object {
        private const val TAG = "DavCalendarSync"
        private const val YEAR_MILLIS = 365L * 24 * 60 * 60 * 1000
        private val client = OkHttpClient.Builder()
            .connectTimeout(20, java.util.concurrent.TimeUnit.SECONDS)
            .readTimeout(60, java.util.concurrent.TimeUnit.SECONDS)
            .build()
    }
}