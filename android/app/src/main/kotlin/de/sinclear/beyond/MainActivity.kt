package de.sinclear.beyond

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import de.sinclear.beyond.dav.DavSyncManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "de.sinclear.beyond/dav_sync"
        private const val REQUEST_CODE_CALENDAR = 1001

        /** Überlebt die Activity-Recreation (Rotation/Hintergrund), damit ein
         *  laufender Berechtigungs-Dialog sein Ergebnis nicht verliert. */
        private var pendingPermissionCallback: ((Boolean) -> Unit)? = null
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val manager = DavSyncManager(applicationContext)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "enable" -> result.success(
                            manager.enable(
                                email = call.argument<String>("email") ?: "",
                                userId = call.argument<String>("userId") ?: "",
                                davBaseUrl = call.argument<String>("davBaseUrl") ?: "",
                                davToken = call.argument<String>("davToken") ?: "",
                                enabledSegments = call.argument<List<String>>("segments")
                                    ?: emptyList(),
                            ),
                        )
                        "disable" -> {
                            manager.disable()
                            result.success(null)
                        }
                        "syncNow" -> {
                            manager.syncNow()
                            result.success(null)
                        }
                        "isEnabled" -> result.success(manager.isEnabled())
                        "enabledSegments" -> result.success(manager.enabledSegments())
                        "updateSegments" -> {
                            val segments = call.argument<List<String>>("segments") ?: emptyList()
                            result.success(manager.updateSegments(segments))
                        }
                        "lastSyncStatus" -> result.success(manager.lastSyncStatus())
                        "requestCalendarPermission" -> requestCalendarPermission { result.success(it) }
                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    result.error("DAV_SYNC", e.message, null)
                }
            }
    }

    private fun requestCalendarPermission(callback: (Boolean) -> Unit) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            // Vor Android 6 sind gefährliche Berechtigungen zur Installationszeit erteilt.
            callback(true)
            return
        }
        if (checkSelfPermission(Manifest.permission.WRITE_CALENDAR) ==
            PackageManager.PERMISSION_GRANTED
        ) {
            callback(true)
            return
        }
        pendingPermissionCallback = callback
        requestPermissions(
            arrayOf(
                Manifest.permission.READ_CALENDAR,
                Manifest.permission.WRITE_CALENDAR,
            ),
            REQUEST_CODE_CALENDAR,
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != REQUEST_CODE_CALENDAR) return
        val granted = permissions.indices.any {
            permissions[it] == Manifest.permission.WRITE_CALENDAR &&
                grantResults[it] == PackageManager.PERMISSION_GRANTED
        }
        pendingPermissionCallback?.invoke(granted)
        pendingPermissionCallback = null
    }
}
