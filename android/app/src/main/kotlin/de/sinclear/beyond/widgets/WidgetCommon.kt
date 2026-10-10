package de.sinclear.beyond.widgets

import android.content.Context
import android.content.res.Configuration
import android.net.Uri
import androidx.compose.ui.graphics.Color
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONObject

// Data-Keys (müssen mit lib/features/widgets/widget_data_sync.dart übereinstimmen).
internal const val KEY_ACTIVITY = "activity"
internal const val KEY_TODAY = "today"
internal const val KEY_TRIP = "trip"
internal const val KEY_THEME = "theme"

// Click-URI-Schema: `beyond://app<route>` → Flutter übernimmt den Pfad als
// go_router-Route (siehe WidgetLaunchHandler).
private const val SCHEME = "beyond"

internal fun widgetData(context: Context) = HomeWidgetPlugin.getData(context)

internal fun launchUri(route: String): Uri = Uri.parse("$SCHEME://app$route")

internal fun parseColor(hex: String?, fallback: Color): Color {
    if (hex.isNullOrBlank()) return fallback
    return try {
        Color(android.graphics.Color.parseColor(hex))
    } catch (_: Exception) {
        fallback
    }
}

/// Die für die Widgets nötigen Farben. Look & Feel bleibt Material 3
/// (Systemschrift, keine Shapes), nur die Farben kommen aus den DesignTokens
/// der aktiven App-Variante (Light/Dark im Theme-Payload).
internal data class WidgetColors(
    val primary: Color,
    val secondary: Color,
    val background: Color,
    val onSurface: Color,
    val onSurfaceVariant: Color,
)

private fun isDark(context: Context): Boolean =
    (context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK) ==
        Configuration.UI_MODE_NIGHT_YES

/// Löst die Token-Farben für die aktuelle Helligkeit auf; fällt vor dem
/// ersten Sync auf die Materia-Pop-Fallback-Palette zurück.
internal fun resolveColors(context: Context): WidgetColors {
    val section = widgetData(context)
        .getString(KEY_THEME, null)
        ?.let { runCatching { JSONObject(it) }.getOrNull() }
        ?.optJSONObject(if (isDark(context)) "dark" else "light")

    fun c(key: String, fb: Long): Color =
        parseColor(section?.optString(key), Color(fb))

    return if (isDark(context)) {
        WidgetColors(
            primary = c("primary", 0xFFA78BFA),
            secondary = c("secondary", 0xFFF0A6D4),
            background = c("background", 0xFF1A0F2E),
            onSurface = c("onSurface", 0xFFF3EEFF),
            onSurfaceVariant = c("onSurfaceVariant", 0xFFB6A8D6),
        )
    } else {
        WidgetColors(
            primary = c("primary", 0xFF7C3AED),
            secondary = c("secondary", 0xFFF472B6),
            background = c("background", 0xFFFDF2F8),
            onSurface = c("onSurface", 0xFF1F1147),
            onSurfaceVariant = c("onSurfaceVariant", 0xFF6B6380),
        )
    }
}
