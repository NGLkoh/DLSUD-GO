package com.dlsud.go

import android.os.Bundle
import android.webkit.WebView
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity(){
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Enable hybrid composition for WebView
        WebView.setWebContentsDebuggingEnabled(true)
    }
}
