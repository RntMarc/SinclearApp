package de.sinclear.beyond.dav

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test
import java.util.Calendar
import java.util.TimeZone

class IcsParserTest {

    private fun utcMillis(year: Int, month: Int, day: Int, hour: Int, minute: Int): Long =
        Calendar.getInstance(TimeZone.getTimeZone("UTC")).apply {
            set(year, month, day, hour, minute, 0)
            set(Calendar.MILLISECOND, 0)
        }.timeInMillis

    @Test
    fun parsesSingleEvent() {
        val ics = """
            BEGIN:VCALENDAR
            VERSION:2.0
            PRODID:-//sabre/dav//EN
            BEGIN:VEVENT
            UID:event-1@sinclear.de
            DTSTAMP:20260814T120000Z
            DTSTART:20260820T090000Z
            DTEND:20260820T100000Z
            SUMMARY:Test-Termin
            DESCRIPTION:Ein Termin
            LOCATION:Barista
            END:VEVENT
            END:VCALENDAR
        """.trimIndent()

        val events = IcsParser.parse(ics)
        assertEquals(1, events.size)
        val event = events.first()
        assertEquals("event-1@sinclear.de", event.uid)
        assertEquals("Test-Termin", event.title)
        assertEquals("Ein Termin", event.description)
        assertEquals("Barista", event.location)
        assertEquals(utcMillis(2026, Calendar.AUGUST, 20, 9, 0), event.startMillis)
        assertEquals(utcMillis(2026, Calendar.AUGUST, 20, 10, 0), event.endMillis)
    }

    @Test
    fun parsesMultipleEvents() {
        val ics = "BEGIN:VEVENT\nUID:a\nDTSTART:20260820T090000Z\nEND:VEVENT\n" +
            "BEGIN:VEVENT\nUID:b\nDTSTART:20260821T090000Z\nEND:VEVENT"
        assertEquals(2, IcsParser.parse(ics).size)
    }

    @Test
    fun endMillisFallsBackToStart() {
        val ics = "BEGIN:VEVENT\nUID:x\nDTSTART:20260820T090000Z\nSUMMARY:Ohne Ende\nEND:VEVENT"
        val event = IcsParser.parse(ics).first()
        assertEquals(event.startMillis, event.endMillis)
    }

    @Test
    fun ignoresNonEventBlocks() {
        val ics = "BEGIN:VCALENDAR\nVERSION:2.0\nBEGIN:VTIMEZONE\nTZID:Europe/Berlin\nEND:VTIMEZONE\nEND:VCALENDAR"
        assertEquals(0, IcsParser.parse(ics).size)
    }

    @Test
    fun unfoldsWrappedLines() {
        val ics = "BEGIN:VEVENT\nUID:y\nDTSTART:20260820T090000Z\nDESCRIPTION:langer Text\n " +
            "der umbrochen wurde\nEND:VEVENT"
        val event = IcsParser.parse(ics).first()
        assertEquals("langer Textder umbrochen wurde", event.description)
    }

    @Test
    fun eventWithoutDateIsDropped() {
        val ics = "BEGIN:VEVENT\nUID:z\nSUMMARY:ohne Zeit\nEND:VEVENT"
        assertEquals(0, IcsParser.parse(ics).size)
    }
}