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
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.width
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import de.sinclear.beyond.MainActivity
import es.antonborri.home_widget.HomeWidgetGlanceWidgetReceiver
import es.antonborri.home_widget.actionStartActivity
import org.json.JSONObject

/// Heute-Widget: die Termine des heutigen Tages (aus `/calendar/all`).
class TodayWidget : GlanceAppWidget() {
    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent { TodayContent(context) }
    }
}

class TodayWidgetReceiver : HomeWidgetGlanceWidgetReceiver<TodayWidget>() {
    override val glanceAppWidget = TodayWidget()
}

@Composable
private fun TodayContent(context: Context) {
    val payload = widgetData(context)
        .getString(KEY_TODAY, null)
        ?.let { runCatching { JSONObject(it) }.getOrNull() }
    val items = payload?.optJSONArray("items")

    val colors = resolveColors(context)
    val compact = LocalSize.current.width < 180.dp

    Column(
        modifier = GlanceModifier
            .fillMaxSize()
            .background(colors.background)
            .padding(16.dp),
        verticalAlignment = Alignment.Vertical.Top,
    ) {
        Text(
            text = "Heute",
            style = TextStyle(
                fontSize = 13.sp,
                fontWeight = FontWeight.Bold,
                color = ColorProvider(colors.primary),
            ),
        )
        Spacer(modifier = GlanceModifier.height(8.dp))

        if (items == null || items.length() == 0) {
            Text(
                text = "Keine Termine",
                style = TextStyle(fontSize = 14.sp, color = ColorProvider(colors.onSurfaceVariant)),
            )
        } else {
            val max = if (compact) 1 else 4
            val n = minOf(items.length(), max)
            for (i in 0 until n) {
                val item = items.optJSONObject(i) ?: continue
                val route = item.optString("route")
                val title = item.optString("title")
                val time = item.optString("time", null)

                Row(
                    verticalAlignment = Alignment.Vertical.CenterVertically,
                    modifier = GlanceModifier
                        .fillMaxWidth()
                        .padding(vertical = 4.dp)
                        .clickable(
                            onClick = actionStartActivity<MainActivity>(
                                context,
                                launchUri(route),
                            ),
                        ),
                ) {
                    Text(
                        text = if (time.isNullOrBlank()) "•" else time,
                        style = TextStyle(
                            fontSize = 13.sp,
                            fontWeight = FontWeight.Bold,
                            color = ColorProvider(colors.secondary),
                        ),
                    )
                    Spacer(modifier = GlanceModifier.width(8.dp))
                    Text(
                        text = title,
                        style = TextStyle(fontSize = 14.sp, color = ColorProvider(colors.onSurface)),
                    )
                }
            }
        }
    }
}
