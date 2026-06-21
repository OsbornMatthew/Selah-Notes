# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Hive
-keep class hive.** { *; }
-keep class com.hive.** { *; }
-keepclassmembers class * extends hive.HiveObject { *; }
-keep class * implements hive.TypeAdapter { *; }

# Kotlin
-keep class kotlin.** { *; }
-dontwarn kotlin.**

# Keep all model classes
-keep class com.selahnotes.app.** { *; }

# Prevent stripping of annotations
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions
