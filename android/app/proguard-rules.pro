# Room looks up generated database implementations via reflection
# (Class.forName("<Database>_Impl")), so R8 must not rename or strip them.
# WorkManager (pulled in by google_mobile_ads) creates WorkDatabase this way
# at process startup; without these rules every release build crashes on
# launch with "Failed to create an instance of androidx.work.impl.WorkDatabase".
-keep class * extends androidx.room.RoomDatabase { <init>(); }
-keep class androidx.work.impl.WorkDatabase_Impl { *; }

# ML Kit barcode scanning (mobile_scanner). ML Kit registers its components by
# reflectively instantiating *Registrar classes through their no-arg
# constructor. R8 was stripping those constructors, causing
# "NoSuchMethodException: com.google.mlkit...BarcodeRegistrar.<init> []" and a
# null scanner ("Attempt to invoke virtual method ... on a null object
# reference") the moment the scan screen opens.
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_barcode.** { *; }
-dontwarn com.google.mlkit.**
