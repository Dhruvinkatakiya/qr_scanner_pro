# QR Scanner Pro — Implementation Checklist

Status of everything in the spec: **what is implemented in code** vs. **what
still needs a dashboard/account** (things that can only be done outside the repo).

Legend: ✅ done · 🟡 implemented, needs your keys/config · ⬜ optional / not
wired (by request)

---

## 1. Scan engine
- ✅ Live camera scanning (`mobile_scanner` / ML Kit, on-device)
- ✅ Zoom (slider → `setZoomScale`), torch, front/back camera flip
- ✅ Scan from gallery (`image_picker` → `analyzeImage`)
- ✅ Batch / continuous scan mode (Pro-gated) with a running counter
- ✅ Multi-format: QR, EAN-13/8, UPC-A/E, Code 128/39/93, Codabar, ITF, PDF417,
  Data Matrix, Aztec
- ✅ Haptic + sound feedback on scan, toggleable in Settings
- ✅ Animated scan-window overlay with corner brackets + sweep line
- 🟡 Pinch-to-zoom: a zoom **slider** is implemented; pinch-gesture zoom can be
  layered on with a `GestureDetector` if desired

## 2. Smart result handling
- ✅ Auto-classify: URL, Wi-Fi, contact, email, phone, SMS, geo, calendar,
  crypto, plain text (`QrParserService`)
- ✅ URL safety heuristic (shorteners, raw IPs, `@`-obfuscation, punycode, risky
  TLDs, deep subdomains) with a caution/danger banner + confirm-before-open
- ✅ Pluggable `UrlSafetyAnalyzer` interface for a future Safe Browsing API
- ✅ Type-specific quick actions: Open, Copy, Share, Call, Message, Email,
  Open in Maps, copy Wi-Fi password, copy crypto address, add-to-calendar (share)
- 🟡 **Wi-Fi one-tap connect** — copy-password + share is implemented; true
  auto-connect needs a small platform channel using Android's
  `WifiNetworkSuggestion` API (permissions already declared in the manifest)
- 🟡 **Save-to-Contacts / Add-to-Calendar as native records** — currently
  call/message/email/share actions + share-vCard/ICS; full native insert needs
  an intent plugin (e.g. `add_2_calendar`, `flutter_contacts`)

## 3. QR generator
- ✅ Generate for URL, Text, Wi-Fi, Email, Phone, SMS, Location, Contact, Crypto
- ✅ Custom foreground/background colors, gradient fill, square/dot modules,
  rounded eyes, center logo embed (Pro-gated), live preview
- ✅ Export to PNG (multiple resolutions via `pixelRatio`), save to gallery,
  share
- ✅ Generated codes saved to history with their style config
- 🟡 SVG export — PNG is implemented; SVG can be added later
- 🟡 Calendar/Event generator UI — model + `QrContentBuilder.event()` exist; the
  event form is not surfaced in the generator UI yet (easy to add)

## 4. History & organization
- ✅ Every scan + generated code saved with timestamp, type, format
- ✅ Folders/tags (create, color, delete, filter, per-row move)
- ✅ Favorites / pinned filter
- ✅ Search + filters (query, type via chips, folder, favorites, created)
- ✅ Swipe actions: swipe-to-delete, swipe-to-favorite; row menu for move/delete
- ✅ **Local backup & restore** (export/share JSON, import via paste) — no account
- ⬜ Cloud sync — abstraction + drop-in Firebase impl provided but **not wired**
  (per request to avoid Firebase). See README appendix.

## 5. Home dashboard
- ✅ Quick tiles: Scan, Create QR
- ✅ Recent scans preview + View all
- ✅ Usage stats (this month / total / favorites)
- ✅ Upgrade shortcut for free users

## 6. Settings & premium
- ✅ Theme light/dark/system + 8 accent colors
- ✅ Language selector (EN, ES, FR, DE, PT, HI)
- ✅ Sound / haptics / auto-open toggles
- ✅ Paywall with monthly/yearly plans, features, restore, terms
- ✅ Restore purchases flow
- ✅ About: privacy policy, rate app, contact support, version
- 🟡 Subscription tiers via Play Billing — code complete; **create the products
  in Play Console** (see below)

## 7. Platform polish
- ✅ Home-screen widget (Android App Widget → Scan / Create)
- ✅ App shortcuts (long-press icon → Scan / Create) with deep-link handling via
  a MethodChannel
- ✅ Permission flows with rationale + graceful denial (open-settings)
- ✅ Onboarding (3 slides) on first launch
- ✅ Empty / loading / error states throughout

---

## 🔧 Requires action outside the code (dashboards / accounts)

| # | Task | Where | Notes |
|---|------|-------|-------|
| 1 | Create subscription products `qr_pro_monthly`, `qr_pro_yearly` | Google Play Console | Or edit IDs in `lib/utils/constants.dart` |
| 2 | Add license testers + upload to a testing track | Play Console | So purchases populate + are free in test |
| 3 | Create AdMob app + banner/interstitial units | AdMob console | Replace test App ID in `AndroidManifest.xml` and unit IDs in `constants.dart` |
| 4 | Create a signing keystore + `android/key.properties` | local machine | Wire release `signingConfig` (README → Signing) |
| 5 | Replace placeholder links | `lib/utils/constants.dart` | `privacyPolicyUrl`, `supportEmail`, `playStoreUrl`, `applicationId` |
| 6 | App icon / branding | `android/app/src/main/res/mipmap-*` | Currently the default Flutter icon |
| 7 | *(optional)* Firebase project + config | Firebase console | Only if you want cloud sync — see README appendix; **not required** |

---

## ✅ Verified in this environment
- `flutter pub get` — resolves
- `flutter analyze` — **No issues found!**
- `flutter test` — parser/URL-safety unit tests pass
- `flutter build apk --debug` — **builds successfully**

## ⚠️ Needs a device/emulator to verify end-to-end
Camera scanning, gallery import, ad rendering, purchase flow, gallery save,
share sheet, launcher shortcuts and the home-screen widget depend on device
hardware / Google Play services and should be smoke-tested on a real device or
emulator with Play services.
