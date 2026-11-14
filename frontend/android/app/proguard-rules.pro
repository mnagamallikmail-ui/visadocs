# ==============================================================================
# ProValuer Commercial - R8 ProGuard Optimization Rules
# Ensures Flutter Engine, Platform Channels, and Plugins are retained cleanly.
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. Flutter Core Framework & Embedding
# ------------------------------------------------------------------------------
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# ------------------------------------------------------------------------------
# 2. Native Method & Annotation Preservation
# ------------------------------------------------------------------------------
-keepclasseswithmembers class * {
    native <methods>;
}

-keepclassmembers class * extends java.lang.Enum {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod
-keepattributes SourceFile,LineNumberTable

# ------------------------------------------------------------------------------
# 3. Essential Plugins Keep Rules
# ------------------------------------------------------------------------------
# GPS & Geolocation
-keep class com.baseflow.geolocator.** { *; }
-keep class com.google.android.gms.location.** { *; }

# Camera & Photo Capture
-keep class io.flutter.plugins.imagepicker.** { *; }
-keep class androidx.core.content.FileProvider { *; }

# Flutter Secure Storage & Keystore
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# Local Biometric Authentication
-keep class io.flutter.plugins.localauth.** { *; }
-keep class androidx.biometric.** { *; }

# Shared Preferences & Offline Queue
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# Connectivity Plus (Offline Sync Engine)
-keep class dev.fluttercommunity.plus.connectivity.** { *; }

# URL Launcher (Auto Update Delegation)
-keep class io.flutter.plugins.urllauncher.** { *; }

# Open FileX (Document & APK Opener)
-keep class com.crazecoder.openfile.** { *; }

# ------------------------------------------------------------------------------
# 4. Suppress non-fatal dependency warnings
# ------------------------------------------------------------------------------
-dontwarn **
-dontnote **

