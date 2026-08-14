package de.sinclear.beyond.dav

import android.app.Service
import android.content.Intent
import android.os.IBinder

class DavCalendarSyncService : Service() {
    private lateinit var adapter: DavCalendarSyncAdapter

    override fun onCreate() {
        super.onCreate()
        adapter = DavCalendarSyncAdapter(applicationContext, true)
    }

    override fun onBind(intent: Intent?): IBinder = adapter.syncAdapterBinder
}