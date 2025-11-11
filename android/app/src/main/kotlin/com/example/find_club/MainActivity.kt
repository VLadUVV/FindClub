package com.example.find_club

import io.flutter.embedding.android.FlutterActivity
import android.os.Bundle
import com.yandex.mapkit.MapKitFactory

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Устанавливаем API ключ до создания Activity
        MapKitFactory.setApiKey("089ba371-1c65-42b7-b91c-a2528564a5cb")
        super.onCreate(savedInstanceState)
    }
}
