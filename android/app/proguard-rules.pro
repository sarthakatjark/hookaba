# Keep Signify Hue classes
-keep class com.signify.hue.** { *; }

# Keep Bluetooth related classes
-keep class * extends android.bluetooth.** { *; }
-keep class * implements android.bluetooth.** { *; } 