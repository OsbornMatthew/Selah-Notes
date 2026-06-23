# Flutter engine
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase — keep necessary reflection targets
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Firestore serialization
-keepattributes Signature
-keepattributes *Annotation*
-keepclassmembers class * {
    @com.google.firebase.firestore.PropertyName <fields>;
}

# flutter_quill
-keep class com.github.fleaflet.** { *; }
-dontwarn com.github.fleaflet.**

# share_plus
-keep class dev.fluttercommunity.plus.share.** { *; }

# pdf / screenshot / path_provider
-dontwarn org.bouncycastle.**
-dontwarn org.conscrypt.**
-dontwarn org.openjsse.**

# General: keep class names used in reflection
-keepattributes EnclosingMethod
-keepattributes InnerClasses
