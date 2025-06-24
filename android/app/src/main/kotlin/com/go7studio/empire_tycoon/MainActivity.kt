package com.go7studio.empire_tycoon

import io.flutter.embedding.android.FlutterActivity
import android.os.Bundle
import com.google.android.gms.games.PlayGamesSdk

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Initialize Google Play Games Services v2 SDK
        // This is REQUIRED for Google Play Console to recognize the integration
        PlayGamesSdk.initialize(this)
    }
}
