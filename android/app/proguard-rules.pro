# Room looks up generated database implementations via reflection
# (Class.forName("<Database>_Impl")), so R8 must not rename or strip them.
# WorkManager (pulled in by google_mobile_ads) creates WorkDatabase this way
# at process startup; without these rules every release build crashes on
# launch with "Failed to create an instance of androidx.work.impl.WorkDatabase".
-keep class * extends androidx.room.RoomDatabase { <init>(); }
-keep class androidx.work.impl.WorkDatabase_Impl { *; }
