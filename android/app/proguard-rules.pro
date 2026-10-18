# Proguard / R8 rules for Dozetone release builds

# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-dontwarn io.flutter.**
-keep class io.flutter.plugins.**  { *; }
-dontwarn com.google.android.play.core.**

# audio_service rules
-keep class com.ryanheise.audioservice.** { *; }
-dontwarn com.ryanheise.audioservice.**
-keep public class com.ryanheise.audioservice.MediaButtonReceiver { *; }
-keep class androidx.media.** { *; }
-dontwarn androidx.media.**
-keep class androidx.media3.** { *; }
-dontwarn androidx.media3.**

# just_audio rules
-keep class com.ryanheise.justaudio.** { *; }
-dontwarn com.ryanheise.justaudio.**

# Dozetone native plugin & activities
-keep class com.velcruxlab.dozetone.** { *; }
