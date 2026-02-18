# Flutter ProGuard Rules for LoadRunner Admin

# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Supabase / PostgREST
-keep class io.supabase.** { *; }
-keep class com.google.gson.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }

# OkHttp / HTTP client
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }

# Prevent stripping of Kotlin metadata
-keep class kotlin.Metadata { *; }
-keepattributes *Annotation*

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}
