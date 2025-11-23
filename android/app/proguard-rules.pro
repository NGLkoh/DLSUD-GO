# Flutter Engine
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.embedding.**  { *; }
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Google Play Core Library
-keep class com.google.android.play.core.** { *; }
-keep interface com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Mapbox
-keep class com.mapbox.** { *; }
-keep interface com.mapbox.** { *; }
-dontwarn com.mapbox.**

# Geolocator
-keep class com.baseflow.geolocator.** { *; }
-keep interface com.baseflow.geolocator.** { *; }
-dontwarn com.baseflow.geolocator.**
