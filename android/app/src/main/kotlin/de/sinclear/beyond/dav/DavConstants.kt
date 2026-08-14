package de.sinclear.beyond.dav

/** Zentrale Konstanten für die native CalDAV-Synchronisation. */
object DavConstants {
    /** Eigene Account-Type des App-eigenen SyncAdapter-Accounts. */
    const val ACCOUNT_TYPE = "de.sinclear.beyond.dav"

    /** Authority des System-Kalenders (CalendarContract.AUTHORITY). */
    const val CALENDAR_AUTHORITY = "com.android.calendar"

    /** Fester Kalender-Name innerhalb des Accounts (Identifikation). */
    const val CALENDAR_NAME = "sinclear-beyond"

    /** Anzeigename des Kalenders in der Systemkalender-App. */
    const val CALENDAR_DISPLAY_NAME = "Beyond Kalender"

    const val KEY_USER_ID = "userId"
    const val KEY_DAV_BASE_URL = "davBaseUrl"
    const val KEY_DAV_TOKEN = "davToken"
    const val KEY_LAST_SYNC = "lastSync"
    const val KEY_LAST_ERROR = "lastError"

    /** Periodischer Sync (Mindestintervall Android ist 60 Minuten). */
    const val SYNC_PERIOD_SECONDS = 12L * 60 * 60
}