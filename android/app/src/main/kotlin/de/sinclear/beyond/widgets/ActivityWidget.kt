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
import androidx.glance.layout.fillMaxWidth
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

/// Aktivität-Widget: Zähler ungelesener Forum-Beiträge + bis zu drei
/// tappbare Einträge.
class ActivityWidget : GlanceAppWidget() {
    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent { ActivityContent(context) }
    }
}

class ActivityWidgetReceiver : HomeWidgetGlanceWidgetReceiver<ActivityWidget>() {
    override val glanceAppWidget = ActivityWidget()
}

@Composable
private fun ActivityContent(context: Context) {
    val payload = widgetData(context)
        .getString(KEY_ACTIVITY, null)
        ?.let { runCatching { JSONObject(it) }.getOrNull() }
    val total = payload?.optInt("total", 0) ?: 0
    val items = payload?.optJSONArray("items")

    val colors = resolveColors(context)
    val compact = LocalSize.current.width < 180.dp

    Column(
        modifier = GlanceModifier
            .fillMaxSize()
            .background(colors.background)
            .padding(16.dp)
            .clickable(
                onClick = actionStartActivity<MainActivity>(
                    context,
                    launchUri("/forum"),
                ),
            ),
        verticalAlignment = Alignment.Vertical.Top,
    ) {
        Text(
            text = when {
                total == 0 -> "Keine neuen Beiträge"
                else -> "$total ungelesen"
            },
            style = TextStyle(
                fontSize = if (compact) 20.sp else 22.sp,
                fontWeight = FontWeight.Bold,
                color = ColorProvider(colors.primary),
            ),
        )
        if (total > 0 && items != null) {
            Spacer(modifier = GlanceModifier.height(8.dp))
            val max = if (compact) 1 else 3
            val n = minOf(items.length(), max)
            for (i in 0 until n) {
                val item = items.optJSONObject(i) ?: continue
                Text(
                    text = item.optString("label"),
                    style = TextStyle(
                        fontSize = 13.sp,
                        color = ColorProvider(colors.onSurfaceVariant),
                    ),
                    modifier = GlanceModifier
                        .fillMaxWidth()
                        .padding(vertical = 4.dp)
                        .clickable(
                            onClick = actionStartActivity<MainActivity>(
                                context,
                                launchUri(item.optString("route")),
                            ),
                        ),
                )
            }
        }
    }
}
