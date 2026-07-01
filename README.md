# QR Scanner Pro

A premium, production-grade QR & barcode scanner for Android built with Flutter.
On-device ML Kit scanning, smart type-aware result handling with URL safety
checks, a customizable QR generator, an offline-first history with folders and
favorites, localization in 6 languages, and a freemium (ads + subscription)
model.

> **Runs 100% offline, with no accounts and no Firebase.** History and a local
> backup/restore feature work entirely on-device. Ads use Google's official
> **test** IDs and subscriptions degrade gracefully until you configure Play
> Billing — so the project builds and runs immediately with zero setup. Optional
> Firebase cloud sync is available as a drop-in extra (see the appendix) but is
> **not required and not enabled**.

---

## ✨ Features

- **Advanced scan engine** — live camera scanning with slider zoom, torch,
  camera flip, **scan-from-gallery**, and a Pro **batch/continuous** mode.
- **Multi-format** — QR, EAN-13/8, UPC-A/E, Code 128/39/93, Codabar, ITF,
  PDF417, Data Matrix, Aztec.
- **Smart results** — auto-classifies URL, Wi-Fi, contact (vCard/MECARD), email,
  phone, SMS, geo, calendar event, crypto and plain text, each with
  type-specific quick actions (open, call, message, email, maps, copy, share…).
- **URL safety** — a fully **offline** heuristic flags URL shorteners, raw-IP
  hosts, credential-in-URL tricks, punycode homographs and risky TLDs before you
  open a link. The analyzer is pluggable (`UrlSafetyAnalyzer`) so a Safe Browsing
  API can be added later without touching the UI.
- **QR generator** — 9 content types, custom foreground/background colors,
  gradient fill, square/dot styles, rounded eyes, center-logo embedding, live
  preview, save-to-gallery + share.
- **History & organization** — offline-first (Hive), search, filters, folders,
  favorites, swipe actions (favorite / delete), and per-row move-to-folder.
- **Local backup & restore** — export your entire history + folders to a
  portable JSON file (share to Drive, email, another device) and restore by
  pasting it back. No server, no account.
- **Freemium** — Google Play Billing subscriptions (monthly/yearly), a polished
  paywall, restore purchases, and AdMob banner/interstitial ads for free users
  (auto-hidden for Pro).
- **Platform polish** — 3-slide onboarding, permission rationale flows, launcher
  shortcuts, a home-screen quick-scan widget, light/dark/system themes with 8
  accent colors, haptic + sound feedback, and localization
  (EN, ES, FR, DE, PT, HI).

---

## 🧱 Architecture

```
lib/
  main.dart                 App bootstrap (Hive, localization, ads, ProviderScope)
  app/                      Root MaterialApp + theming wiring
  models/                   ScanRecord, QrStyleConfig, UserSubscription, ContentType…
  services/                 storage (Hive), scanner, qr_parser (+ URL safety),
                            qr_content_builder, qr_export, billing, ads,
                            permission, backup, notifications, intent, cloud_sync
  providers/                Riverpod providers (settings, history, folders,
                            subscription, services)
  screens/                  home · scan · generate · history · settings ·
                            onboarding · paywall · result · root shell
  widgets/                  RecordTile, EmptyState, BannerAd, StyledQrView, …
  theme/                    Material 3 theme + accent palette
  utils/                    constants, formatters, launch helpers, feedback
assets/translations/        en/es/fr/de/pt/hi JSON (easy_localization)
```

- **State management:** Riverpod 3 (`Notifier` / derived `Provider`s).
- **Persistence:** Hive — records/folders stored as JSON (no code-gen adapters),
  forward-compatible.
- **Dependency injection:** services are exposed through providers, so ads,
  billing and the (optional) cloud layer can be overridden or mocked.

---

## 🚀 Getting started

Requirements: Flutter **3.44+** (Dart 3.12+), Android SDK, a device/emulator on
**API 23+**.

```bash
flutter pub get
flutter run                 # debug on a connected device/emulator
flutter analyze             # static analysis → "No issues found!"
flutter test                # unit tests (parser / URL-safety logic)
flutter build apk --debug   # produces build/app/outputs/flutter-apk/app-debug.apk
```

No extra configuration is required to run. Ads show test creatives; the paywall
shows placeholder prices until Play Billing is configured (below).

---

## 💳 Google Play Billing (subscriptions)

Product IDs live in `lib/utils/constants.dart`:

```dart
static const String proMonthlyId = 'qr_pro_monthly';
static const String proYearlyId  = 'qr_pro_yearly';
```

1. In **Play Console → Monetize → Subscriptions**, create two subscriptions with
   **exactly** those IDs (or edit the constants to match yours).
2. Add base plans + prices and activate them.
3. Upload a build to a testing track and add **license testers**
   (Setup → License testing) so purchases are free while testing.
4. Install from that track — real prices then populate the paywall and a purchase
   grants Pro. Entitlement is handled in `BillingService` /
   `SubscriptionNotifier`, cached locally, and recoverable via **Restore
   purchases** in Settings/paywall.

> For production, verify purchases server-side (Play Developer API) or use a
> service like RevenueCat. The current flow trusts the on-device purchase stream —
> fine for launch, not fraud-proof.

---

## 📣 AdMob

The manifest and `lib/utils/constants.dart` ship with Google's **official test**
App ID and ad unit IDs, so ads work in debug with no account. Before release:

1. Create an AdMob app and banner + interstitial ad units.
2. Replace the `com.google.android.gms.ads.APPLICATION_ID` value in
   `android/app/src/main/AndroidManifest.xml`.
3. Replace `testBannerAdUnit` / `testInterstitialAdUnit` in `constants.dart`.

Ads are automatically disabled for Pro users.

---

## 📦 Building a release

### App Bundle (recommended for Play)
```bash
flutter build appbundle --release
# build/app/outputs/bundle/release/app-release.aab
```

### APK
```bash
flutter build apk --release
```

### Signing

1. Create a keystore:
   ```bash
   keytool -genkey -v -keystore ~/qr-scanner-pro.jks \
     -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
2. Create `android/key.properties` (do **not** commit it):
   ```properties
   storePassword=********
   keyPassword=********
   keyAlias=upload
   storeFile=/absolute/path/to/qr-scanner-pro.jks
   ```
3. Wire it into `android/app/build.gradle.kts`: load `key.properties`, add a
   `signingConfigs { create("release") { … } }`, and set
   `buildTypes { release { signingConfig = signingConfigs.getByName("release") } }`
   (replacing the debug placeholder). See
   <https://docs.flutter.dev/deployment/android#signing-the-app>.

The app targets **minSdk 23** (required by ML Kit + Ads) and enables
**core-library desugaring** (required by `flutter_local_notifications`) — both are
already configured in `android/app/build.gradle.kts`.

---

## 🌐 Localization

Translations live in `assets/translations/*.json` (loaded via
`easy_localization`). Add a language by dropping in a `<code>.json`, adding the
`Locale` to `supportedLocales` in `main.dart`, and adding it to `_languages` in
the settings screen.

---

## 🔒 Backup & restore (local, no account)

**Settings → Export backup** writes a JSON snapshot of your history + folders and
opens the share sheet (save to Files, Drive, email, etc.). **Settings → Import
backup** restores by pasting that JSON back in; existing items are de-duplicated
by id. Everything stays on-device — no sign-in, no server.

---

## 🧪 Tests

`test/widget_test.dart` covers the parser / URL-safety logic (URL classification,
suspicious-URL flagging, Wi-Fi parsing, plain-text fallback). Run `flutter test`.

---

## Appendix — Optional Firebase cloud sync (off by default)

Cloud sync is **not used** by the app. If you ever want cross-device sync in
addition to local backup, the code is structured for it: `CloudSyncService` is an
abstraction whose default is a no-op `LocalOnlyCloudSyncService`, and a complete
Firestore/Auth implementation is provided (uncompiled) at
`lib/services/firebase_cloud_sync_service.dart.example`. To enable it you would:

1. `flutter pub add firebase_core firebase_auth cloud_firestore google_sign_in`
2. `flutterfire configure` (adds `google-services.json` + `firebase_options.dart`)
   and apply the `com.google.gms.google-services` Gradle plugin.
3. Enable **Anonymous** + **Google** auth and **Cloud Firestore** in the Firebase
   console.
4. Rename the `.example` file, uncomment it, initialise Firebase in `main.dart`,
   and override `cloudSyncServiceProvider` with `FirebaseCloudSyncService()`.

Suggested Firestore rules (per-user isolation, data at `users/{uid}/scans/*`):

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

See **`CHECKLIST.md`** for the full implemented-vs-manual-setup breakdown.
