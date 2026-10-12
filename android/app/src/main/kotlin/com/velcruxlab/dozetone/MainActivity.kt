package com.velcruxlab.dozetone

import android.content.Intent
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine

/**
 * MainActivity for Dozetone.
 * Extends AudioServiceActivity to support background audio controls
 * and registers native plugins.
 */
class MainActivity : AudioServiceActivity() {
    private var mediaStorePlugin: MediaStorePlugin? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        mediaStorePlugin = MediaStorePlugin.registerWith(flutterEngine, this)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        mediaStorePlugin?.handleActivityResult(requestCode, resultCode)
    }
}
