package de.sinclear.beyond.dav

import java.text.SimpleDateFormat
import java.util.Locale
import java.util.TimeZone

/** Ein aus der CalDAV-ICS-Antwort extrahiertes Event. */
data class DavEvent(
    val uid: String,
    val startMillis: Long,
    val endMillis: Long,
    val title: String?,
    val description: String?,
    val location: String?,
)

/**
 * Minimaler iCalendar-Parser: liest nur die Felder, die die Sinclear-API
 * exportiert (UID/DTSTART/DTEND/SUMMARY/DESCRIPTION/LOCATION), UTC-only.
 */
object IcsParser {
    private const val DATE_TIME_PATTERN = "yyyyMMdd'T'HHmmss'Z'"
    private val allowedKeys = setOf(
        "UID", "DTSTART", "DTEND", "SUMMARY", "DESCRIPTION", "LOCATION",
    )

    fun parse(ics: String): List<DavEvent> {
        val events = mutableListOf<DavEvent>()
        var fields = mutableMapOf<String, String>()
        var inEvent = false
        var lastKey: String? = null

        for (rawLine in ics.lines()) {
            // Gebletete (umgebrochene) Zeilen wieder zusammenfügen.
            if (inEvent && rawLine.isNotEmpty() && (rawLine[0] == ' ' || rawLine[0] == '\t')) {
                val key = lastKey ?: continue
                fields[key] = (fields[key] ?: "") + rawLine.substring(1)
                continue
            }
            lastKey = null
            val line = rawLine.trimEnd('\r')
            if (line.startsWith("BEGIN:VEVENT")) {
                fields = mutableMapOf()
                inEvent = true
                continue
            }
            if (line.startsWith("END:VEVENT")) {
                fields.toEvent()?.let(events::add)
                inEvent = false
                continue
            }
            if (!inEvent) continue
            val colon = line.indexOf(':')
            if (colon < 0) continue
            val key = line.substring(0, colon).substringBefore(';')
            lastKey = key
            if (key in allowedKeys) fields[key] = line.substring(colon + 1)
        }
        return events
    }

    private fun Map<String, String>.toEvent(): DavEvent? {
        val uid = this["UID"] ?: return null
        val start = parseTime(this["DTSTART"]) ?: return null
        val end = parseTime(this["DTEND"]) ?: start
        return DavEvent(
            uid = uid,
            startMillis = start,
            endMillis = end,
            title = this["SUMMARY"],
            description = this["DESCRIPTION"],
            location = this["LOCATION"],
        )
    }

    private fun parseTime(value: String?): Long? {
        if (value.isNullOrBlank()) return null
        val format = SimpleDateFormat(DATE_TIME_PATTERN, Locale.US)
        format.timeZone = TimeZone.getTimeZone("UTC")
        return try {
            format.parse(value.trim())?.time
        } catch (_: Exception) {
            null
        }
    }
}