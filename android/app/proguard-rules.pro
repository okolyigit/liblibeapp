# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Models (if using json_serializable or similar reflection-based libs)
# -keep class com.example.liblibeapp.models.** { *; }

# Firestore
-keep class com.google.cloud.firestore.** { *; }
-keep class io.grpc.** { *; }

# Prevent warnings
-dontwarn io.flutter.**
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**
-dontwarn com.squareup.okhttp.**
-keep class com.squareup.okhttp.** { *; }
-dontwarn javax.annotation.**

