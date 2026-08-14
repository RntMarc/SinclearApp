package de.sinclear.beyond.dav

/** Zentrale Konstanten für die native CalDAV-Synchronisation. */
object DavConstants {
    /** Eigene Account-Type des App-eigenen SyncAdapter-Accounts. */
    const val ACCOUNT_TYPE = "de.sinclear.beyond.dav"

    /** Authority des System-Kalenders (CalendarContract.AUTHORITY). */
    const val CALENDAR_AUTHORITY = "com.android.calendar"

    const val KEY_USER_ID = "userId"
    const val KEY_DAV_BASE_URL = "davBaseUrl"
    const val KEY_DAV_TOKEN = "davToken"
    const val KEY_LAST_SYNC = "lastSync"
    const val KEY_LAST_ERROR = "lastError"

    /** Komma-separierte Liste der aktivierten Kalender-Segmente. */
    const val KEY_ENABLED_SEGMENTS = "enabledSegments"

    /** Periodischer Sync (Mindestintervall Android ist 60 Minuten). */
    const val SYNC_PERIOD_SECONDS = 12L * 60 * 60

    /**
     * Die drei von der DAV-API ausgelieferten Kalender (identisch zu
     * `GET /calendar/all`, gefiltert nach `type`). Farben gemäß API-Doku.
     */
    val CALENDARS = listOf(
        CalendarKind(
            segment = "calendar",
            name = "sinclear-beyond",
            displayName = "Beyond Kalender",
            color = 0xFF6366F1.toInt(),
        ),
        CalendarKind(
            segment = "travel",
            name = "sinclear-beyond-travel",
            displayName = "Reisen & Fahrten",
            color = 0xFFF59E0B.toInt(),
        ),
        CalendarKind(
            segment = "birthdays",
            name = "sinclear-beyond-birthdays",
            displayName = "Geburtstage",
            color = 0xFFEC4899.toInt(),
        ),
    )
}

/** Ein abonnierbarer Beyond-Kalender (Segment in der DAV-URL, Name und Farbe). */
data class CalendarKind(
    val segment: String,
    val name: String,
    val displayName: String,
    val color: Int,
)
