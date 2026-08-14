package de.sinclear.beyond.dav

import android.app.Service
import android.content.Intent
import android.os.IBinder

class DavAuthenticatorService : Service() {
    private lateinit var authenticator: DavAuthenticator

    override fun onCreate() {
        super.onCreate()
        authenticator = DavAuthenticator(this)
    }

    override fun onBind(intent: Intent?): IBinder = authenticator.iBinder
}