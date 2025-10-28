# TensorFlow Lite GPU Delegate
-keep class org.tensorflow.lite.** { *; }
-keepclassmembers class org.tensorflow.lite.** { *; }

# Keep GPU delegate classes
-keep class org.tensorflow.lite.gpu.** { *; }
-keepclassmembers class org.tensorflow.lite.gpu.** { *; }

# Suppress warnings for GPU delegate factory options
-dontwarn org.tensorflow.lite.gpu.GpuDelegateFactory$Options

# Keep all native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# UCrop library
-dontwarn com.yalantis.ucrop**
-keep class com.yalantis.ucrop** { *; }
-keep interface com.yalantis.ucrop** { *; }

# OkHttp (required by UCrop)
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-keep class okio.** { *; }
-keep interface okio.** { *; }
