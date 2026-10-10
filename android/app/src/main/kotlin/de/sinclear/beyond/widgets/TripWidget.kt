package de.sinclear.beyond.widgets

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.LocalSize
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.layout.Alignment
import androidx.glance.layout.Column
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import de.sinclear.beyond.MainActivity
import es.antonborri.home_widget.HomeWidgetGlanceWidgetReceiver
import es.antonborri.home_widget.actionStartActivity
import org.json.JSONObject

/// Nächste-Reise-Widget: Titel, Zeitraum und Countdown der nächsten
/// (laufenden oder bevorstehenden) Reise.
class TripWidget : GlanceAppWidget() {
    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent { TripContent(context) }
    }
}

class TripWidgetReceiver : HomeWidgetGlanceWidgetReceiver<TripWidget>() {
    override val glanceAppWidget = TripWidget()
}

@Composable
private fun TripContent(context: Context) {
    val payload = widgetData(context)
        .getString(KEY_TRIP, null)
        ?.let { runCatching { JSONObject(it) }.getOrNull() }

    val colors = resolveColors(context)
    val compact = LocalSize.current.width < 180.dp

    val route = payload?.optString("route", null).takeUnless { it.isNullOrBlank() }
    val title = payload?.optString("title", null).takeUnless { it.isNullOrBlank() }
    val dateLabel = payload?.optString("dateLabel", null).takeUnless { it.isNullOrBlank() }
    val daysUntil = payload?.optInt("daysUntil", 0)

    Column(
        modifier = GlanceModifier
            .fillMaxSize()
            .background(colors.background)
            .padding(16.dp)
            .clickable(
                onClick = actionStartActivity<MainActivity>(
                    context,
                    launchUri(route ?: "/reisen"),
                ),
            ),
        verticalAlignment = Alignment.Vertical.Top,
    ) {
        Text(
            text = "Nächste Reise",
            style = TextStyle(
                fontSize = 13.sp,
                fontWeight = FontWeight.Bold,
                color = ColorProvider(colors.primary),
            ),
        )
        Spacer(modifier = GlanceModifier.height(8.dp))

        if (title == null) {
            Text(
                text = "Keine Reise geplant",
                style = TextStyle(fontSize = 14.sp, color = ColorProvider(colors.onSurfaceVariant)),
            )
        } else {
            Text(
                text = title,
                style = TextStyle(
                    fontSize = if (compact) 16.sp else 18.sp,
                    fontWeight = FontWeight.Bold,
                    color = ColorProvider(colors.onSurface),
                ),
            )
            if (dateLabel != null) {
                Spacer(modifier = GlanceModifier.height(4.dp))
                Text(
                    text = dateLabel,
                    style = TextStyle(fontSize = 13.sp, color = ColorProvider(colors.onSurfaceVariant)),
                )
            }
            if (daysUntil != null) {
                Spacer(modifier = GlanceModifier.height(4.dp))
                Text(
                    text = when {
                        daysUntil > 0 -> "in $daysUntil Tagen"
                        daysUntil == 0 -> "Heute"
                        else -> "läuft"
                    },
                    style = TextStyle(
                        fontSize = 13.sp,
                        fontWeight = FontWeight.Bold,
                        color = ColorProvider(colors.secondary),
                    ),
                )
            }
        }
    }
}
