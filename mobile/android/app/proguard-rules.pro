# Keep Flutter plugins (Pigeon / JNI / Platform Channels)
-keep class io.flutter.plugins.** { *; }
-keep class dev.flutter.** { *; }
-keep class dev.fluttercommunity.** { *; }
-keep class com.dexterous.** { *; }
-keep class com.it_nomads.** { *; }
-keep class net.wolverinebeach.** { *; }
-keep class com.github.dart_lang.** { *; }

# Keep Kotlin standard library & coroutines used in JNI / Pigeon method descriptors
-keep class kotlin.** { *; }
-keep class kotlinx.** { *; }

# Keep Tink crypto classes used by EncryptedSharedPreferences (flutter_secure_storage)
-keep class com.google.crypto.tink.** { *; }
-dontwarn com.google.errorprone.annotations.**
-dontwarn com.google.android.play.core.**
