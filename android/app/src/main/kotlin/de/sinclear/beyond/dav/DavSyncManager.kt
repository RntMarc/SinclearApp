package de.sinclear.beyond.dav

import android.accounts.Account
import android.accounts.AccountManager
import android.content.ContentResolver
import android.content.Context
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.CalendarContract

/**
 * Verwalter des App-eigenen SyncAdapter-Accounts. Legt den Account samt
 * Zugangsdaten (E-Mail, userId, DAV-Token) im AccountManager an, aktiviert
 * den periodischen Sync und räumt beim Opt-out alles wieder auf.
 */
class DavSyncManager(private val context: Context) {
    private val accountManager = AccountManager.get(context)
    private val resolver = context.contentResolver

    /** Richtet Account + Kalender ein und stößt den ersten Sync an. */
    fun enable(
        email: String,
        userId: String,
        davBaseUrl: String,
        davToken: String,
        enabledSegments: List<String>,
    ): Boolean {
        val account = Account(email, DavConstants.ACCOUNT_TYPE)
        val exists = currentAccount()?.name == email
        if (!exists) {
            if (!accountManager.addAccountExplicitly(account, null, null)) return false
        }
        accountManager.setUserData(account, DavConstants.KEY_USER_ID, userId)
        accountManager.setUserData(account, DavConstants.KEY_DAV_BASE_URL, davBaseUrl)
        accountManager.setUserData(account, DavConstants.KEY_DAV_TOKEN, davToken)
        accountManager.setUserData(account, DavConstants.KEY_LAST_SYNC, null)
        accountManager.setUserData(account, DavConstants.KEY_LAST_ERROR, null)
        setEnabledSegments(account, enabledSegments)

        ContentResolver.setSyncAutomatically(account, DavConstants.CALENDAR_AUTHORITY, true)
        ContentResolver.addPeriodicSync(
            account,
            DavConstants.CALENDAR_AUTHORITY,
            Bundle.EMPTY,
            DavConstants.SYNC_PERIOD_SECONDS,
        )
        ContentResolver.requestSync(
            account,
            DavConstants.CALENDAR_AUTHORITY,
            Bundle.EMPTY,
        )
        return true
    }

    /** Aktualisiert die sichtbaren Kalender-Typen und stößt einen Sync an. */
    fun setEnabledSegments(account: Account, segments: List<String>) {
        accountManager.setUserData(
            account,
            DavConstants.KEY_ENABLED_SEGMENTS,
            segments.joinToString(","),
        )
    }

    /** Ändert die Auswahl der Kalender-Typen zur Laufzeit und synchronisiert. */
    fun updateSegments(segments: List<String>): Boolean {
        val account = currentAccount() ?: return false
        setEnabledSegments(account, segments)
        syncNow()
        return true
    }

    /** Opt-out: Sync stoppen, Kalender (+Events) und Account entfernen. */
    fun disable() {
        val account = currentAccount() ?: return
        ContentResolver.cancelSync(account, DavConstants.CALENDAR_AUTHORITY)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            ContentResolver.removePeriodicSync(
                account,
                DavConstants.CALENDAR_AUTHORITY,
                Bundle.EMPTY,
            )
        }
        ContentResolver.setSyncAutomatically(
            account,
            DavConstants.CALENDAR_AUTHORITY,
            false,
        )
        for (kind in DavConstants.CALENDARS) {
            deleteCalendar(account, kind)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1) {
            accountManager.removeAccountExplicitly(account)
        } else {
            @Suppress("DEPRECATION")
            accountManager.removeAccount(account, null, null)
        }
    }

    /** Stößt sofort einen Sync an (nutzbar z. B. beim App-Start). */
    fun syncNow() {
        val account = currentAccount() ?: return
        val extras = Bundle().apply {
            putBoolean(ContentResolver.SYNC_EXTRAS_EXPEDITED, true)
            putBoolean(ContentResolver.SYNC_EXTRAS_MANUAL, true)
        }
        ContentResolver.requestSync(
            account,
            DavConstants.CALENDAR_AUTHORITY,
            extras,
        )
    }

    fun isEnabled(): Boolean = currentAccount() != null

    /** Aktuell aktivierte Kalender-Segmente (Komma-separiert gespeichert). */
    fun enabledSegments(): List<String> {
        val account = currentAccount() ?: return emptyList()
        return accountManager
            .getUserData(account, DavConstants.KEY_ENABLED_SEGMENTS)
            ?.split(',')
            ?.filter { it.isNotBlank() }
            ?: DavConstants.CALENDARS.map { it.segment }
    }

    /** letzten Fehler- oder Sync-Zeitpunkt als kompakten String. */
    fun lastSyncStatus(): String? = currentAccount()?.let {
        accountManager.getUserData(it, DavConstants.KEY_LAST_ERROR)
            ?: accountManager.getUserData(it, DavConstants.KEY_LAST_SYNC)
    }

    fun currentAccount(): Account? =
        accountManager.getAccountsByType(DavConstants.ACCOUNT_TYPE).firstOrNull()

    private fun deleteCalendar(account: Account, kind: CalendarKind) {
        val calId = queryCalendarId(account, kind) ?: return
        resolver.delete(
            syncUri(CalendarContract.Calendars.CONTENT_URI, account),
            "${CalendarContract.Calendars._ID} = ?",
            arrayOf(calId.toString()),
        )
    }

    private fun queryCalendarId(account: Account, kind: CalendarKind): Long? {
        val projection = arrayOf(CalendarContract.Calendars._ID)
        val selection = "${CalendarContract.Calendars.ACCOUNT_NAME} = ? AND " +
            "${CalendarContract.Calendars.ACCOUNT_TYPE} = ? AND " +
            "${CalendarContract.Calendars.NAME} = ?"
        val args = arrayOf(account.name, DavConstants.ACCOUNT_TYPE, kind.name)
        return resolver.query(
            syncUri(CalendarContract.Calendars.CONTENT_URI, account),
            projection,
            selection,
            args,
            null,
        )?.use { cursor ->
            if (cursor.moveToFirst()) cursor.getLong(0) else null
        }
    }

    companion object {
        /** URI mit SyncAdapter-Parametern, damit (Schreib-)Zugriffe als
         *  SyncAdapter durchgehen und nicht vom Provider blockiert werden. */
        fun syncUri(base: Uri, account: Account): Uri =
            base.buildUpon()
                .appendQueryParameter(CalendarContract.CALLER_IS_SYNCADAPTER, "true")
                .appendQueryParameter(
                    CalendarContract.Calendars.ACCOUNT_NAME,
                    account.name,
                )
                .appendQueryParameter(
                    CalendarContract.Calendars.ACCOUNT_TYPE,
                    account.type,
                )
                .build()
    }
}