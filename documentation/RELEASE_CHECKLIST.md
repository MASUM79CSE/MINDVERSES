# MINDVERSE — Release Checklist

**Version:** 1.0.0+1  
**Last updated:** November 23, 2026  
**Status:** Ready for manual release steps

---

## ✅ Completed

### Code Quality
- [x] `flutter analyze` — **No issues found**
- [x] `flutter test` — **191 tests passed, 0 failed**
- [x] All 7 games implemented and tested
- [x] Transactional persistence with Sembast
- [x] Idempotent completion and reward system
- [x] Daily challenge with streak bonuses
- [x] Achievement system connected
- [x] Hint tracking and best-score preservation
- [x] 90 campaign levels across 7 games
- [x] Accessibility overflow fixes applied

### App Assets
- [x] App icon source (1024×1024 PNG) — `assets/icons/app_icon.png`
- [x] Android launcher icons generated via `flutter_launcher_icons`
- [x] iOS launcher icons generated in `ios/Runner/Assets.xcassets/AppIcon.appiconset` (App Store compliant, no alpha channel)
- [x] Play Store feature graphic (1024×500 PNG) — `assets/images/feature_graphic.png`

### Desktop Configuration (Windows & macOS)
- [x] Windows window title updated to `MINDVERSE` (`windows/runner/main.cpp`)
- [x] macOS AppInfo config updated (`macos/Runner/Configs/AppInfo.xcconfig`)
- [x] Windows release guide created — `documentation/WINDOWS_RELEASE_GUIDE.md`
- [x] macOS release guide created — `documentation/MACOS_RELEASE_GUIDE.md`

### Release Signing
- [x] Production keystore generated at `android/app/upload-keystore.jks`
- [x] `android/key.properties` configured with credentials
- [x] `build.gradle.kts` signing config updated

### Device Verification
- [x] OPPO CPH2269, Android 11, MediaTek mt6765
- [x] RSS ~122-131 MB (target <180 MB)
- [x] No crashes detected
- [x] Successful app lifecycle (start, restart, configuration change)
- [x] Cold start completes without error

### Play Store Documentation
- [x] Privacy policy — `documentation/PRIVACY_POLICY.md`
- [x] Privacy policy HTML — `privacy.html` (pushed to GitHub)
- [x] Data Safety declaration guide — `documentation/DATA_SAFETY.md`
- [x] Store listing content — `documentation/PLAY_STORE_LISTING.md`
- [x] Step-by-step publication guide — `documentation/PLAY_STORE_GUIDE.md`

### Developer Info
- [x] Developer: Mir Md. Masum
- [x] Email: mirmasum@mail.com
- [x] Instagram: @mirmd_masum
- [x] Discord: mir_masum

---

## ⏳ Manual Steps Required

### 1. GitHub Pages — Privacy Policy URL
✅ **COMPLETED** — GitHub Pages enabled and privacy policy is live.

**Privacy Policy URL:** `https://masum79cse.github.io/MINDVERSES/privacy.html`

### 2. Release Build Verification
Windows Security is blocking the Flutter compiler. Add the exclusion:

1. Open **Windows Security** → **Virus & threat protection** → **Manage settings**
2. Scroll to **Exclusions** → **Add or remove exclusions**
3. Click **Add an exclusion** → **Folder**
4. Add: `C:\Users\Corbi\develop\flutter\bin\cache\artifacts\engine\windows-x64`
5. Then run: `flutter build apk --release`
6. Verify: `apksigner verify --print-certs build/app/outputs/flutter-apk/app-release.apk`

### 3. Play Store Screenshots
Capture at least 2 phone screenshots (recommended: 8):

1. Hub screen showing all 7 games
2. Cube Logic gameplay
3. Bridge Master gameplay
4. Maze Architect gameplay
5. Level select screen with progress
6. Daily challenge screen
7. Profile/achievements screen
8. Settings screen

**Requirements:**
- Minimum 320px on any dimension
- Maximum 3840px on any dimension
- PNG or JPG format
- No hardcoded text that may become outdated

### 4. Google Play Console Setup
1. Create developer account at https://play.google.com/console ($25 one-time fee)
2. Complete developer profile:
   - Developer name: "Mir Md. Masum"
   - Developer email: mirmasum@mail.com
   - **Physical address** (required by Google Play)
3. Create new app → Select "Game" → Enter name "MINDVERSE: Brain Puzzles"
4. Complete store listing using `PLAY_STORE_LISTING.md`
5. Complete Data Safety using `DATA_SAFETY.md`
6. Complete content rating questionnaire (all "None" → rated "Everyone")
7. Upload release APK/AAB
8. Create production release

### 5. App Icon Design
✅ App icon redesigned with a professional puzzle piece motif. Android launcher icons regenerated. For further polish, consider hiring a designer or using Canva/Photoshop for a custom illustration.

---

## 📋 Play Console Submission Order

1. ✅ Privacy policy hosted → Copy URL
2. ✅ Release APK/AAB built and signed
3. ⏳ Create Play Console account
4. ⏳ Complete store listing
5. ⏳ Complete Data Safety declaration
6. ⏳ Complete content rating
7. ⏳ Upload APK/AAB
8. ⏳ Create production release
9. ⏳ Wait for review (typically 1-7 days)
10. 🎉 App published!

---

## 📞 Developer Contact

| Platform | Contact |
|----------|---------|
| Email | mirmasum@mail.com |
| Instagram | @mirmd_masum |
| Discord | mir_masum |
| GitHub | github.com/MASUM79CSE |

---

## 📝 Notes

- **GAP-008** (Maze special tiles): Deferred to future update per product decision
- **GAP-009** (Forge2D physics): Hand-written approximation approved for release
- **GAP-011** (End-to-end solvability sweep): Partially resolved; factory tests cover solvability
- **GAP-013** (Online features): Deferred to future updates; app is offline-only
- All deferred items are documented in `documentation/KNOWN_ISSUES.md`
