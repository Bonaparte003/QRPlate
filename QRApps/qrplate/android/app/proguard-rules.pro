# Keep Google Errorprone annotations
-dontwarn com.google.errorprone.annotations.**
-keep class com.google.errorprone.annotations.** { *; }

# Keep javax annotations
-dontwarn javax.annotation.**
-keep class javax.annotation.** { *; }

# Keep Tink crypto related classes
-dontwarn com.google.crypto.tink.**
-keep class com.google.crypto.tink.** { *; }