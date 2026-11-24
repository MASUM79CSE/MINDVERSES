# MINDVERSE — Apple App Store Preparation & Publishing Guide

Step-by-step instructions for publishing MINDVERSE on the Apple App Store and TestFlight.

---

## Prerequisites

- [ ] Apple Developer Program Enrollment ($99/year fee)
- [ ] macOS environment with Xcode (v15+) installed
- [ ] Active Apple Distribution Certificate & App Store Provisioning Profile
- [ ] App ID (`com.mindverse.app`) registered in Apple Developer Portal
- [ ] Publicly accessible Privacy Policy URL (`https://masum79cse.github.io/MINDVERSES/privacy.html`)
- [ ] Generated iOS App Launcher Icons in `ios/Runner/Assets.xcassets/AppIcon.appiconset`

---

## Step 1: Register App ID in Apple Developer Portal

1. Log into [Apple Developer Account](https://developer.apple.com/account/).
2. Navigate to **Certificates, Identifiers & Profiles** → **Identifiers**.
3. Click `+` to add a new App ID:
   * **Type:** App IDs → App
   * **Description:** `MINDVERSE`
   * **Bundle ID:** Explicit → `com.mindverse.app`
4. Enable required capabilities (standard defaults for offline app).
5. Click **Register**.

---

## Step 2: Create App in App Store Connect

1. Go to [App Store Connect](https://appstoreconnect.apple.com/).
2. Navigate to **Apps** → Click `+` → **New App**.
3. Fill in the initial app details:
   * **Platform:** iOS
   * **Name:** `MINDVERSE: Brain Puzzles`
   * **Primary Language:** English (US)
   * **Bundle ID:** Select `com.mindverse.app`
   * **SKU:** `MINDVERSE-IOS-001`
   * **User Access:** Full Access
4. Click **Create**.

---

## Step 3: Configure App Store Metadata

Copy the contents from `APP_STORE_LISTING.md` into App Store Connect:

1. **App Information:**
   * **Name:** `MINDVERSE: Brain Puzzles` (max 30 chars)
   * **Subtitle:** `Think. Solve. Explore.` (max 30 chars)
   * **Category:** Games → Sub-category: Puzzle / Strategy
2. **Pricing and Availability:**
   * **Price Tier:** Free ($0.00)
3. **App Privacy:**
   * **Privacy Policy URL:** `https://masum79cse.github.io/MINDVERSES/privacy.html`
   * Complete privacy questionnaire: Declare **No Data Collected** (MINDVERSE operates 100% offline).
4. **Age Rating:**
   * Complete the age rating questionnaire (Rated 4+ / Everyone).

---

## Step 4: Prepare iOS Build & Archive

On your macOS terminal:

1. Fetch dependencies and install iOS CocoaPods:
   ```bash
   flutter pub get
   cd ios
   pod install
   cd ..
   ```
2. Verify static analysis and tests:
   ```bash
   flutter analyze
   flutter test
   ```
3. Build the release IPA package:
   ```bash
   flutter build ipa --release
   ```
   *Alternative:* Open `ios/Runner.xcworkspace` in Xcode, select **Product → Archive**, and click **Distribute App**.

---

## Step 5: Upload Build to App Store Connect / TestFlight

1. **Via Xcode / Transporter:**
   * Open Xcode Organizer (**Window → Organizer**).
   * Select the archive and click **Distribute App**.
   * Choose **App Store Connect** → **Upload**.
   * Select automatic signing credentials and click **Upload**.
2. **Via Command Line (App Store Connect CLI / Transporter):**
   ```bash
   xcrun altool --upload-app -f build/ios/ipa/MINDVERSE.ipa -u "mirmasum@mail.com" -p "app-specific-password"
   ```

---

## Step 6: Test Flight Internal & External Beta (Optional)

1. Navigate to **TestFlight** tab in App Store Connect.
2. Select your uploaded build (processing usually takes 5-15 minutes).
3. Add **Internal Testers** for immediate testing on physical iPhones/iPads.
4. (Optional) Add **External Testers** for public beta link distribution.

---

## Step 7: Submit for App Store Review

1. Under the **iOS App Version** tab (1.0.0):
   * Attach the uploaded build from TestFlight.
   * Upload required App Store screenshots (6.7" iPhone & 12.9" iPad Pro).
   * Enter Keywords, Description, Support URL, and Marketing URL.
   * Enter Sign-in info: *Not required (App is offline-only)*.
2. Click **Save** → **Submit for Review**.
3. Review approval typically takes **24–48 hours**.

---

## Required iOS Asset Checklist

| Asset | Specifications | Status |
|---|---|---|
| **App Launcher Icon** | 1024×1024 px PNG (No Alpha) | ✅ Generated in `Assets.xcassets` |
| **iPhone 6.7" Display Screenshots** | 1290 × 2796 px or 2796 × 1290 px (Min 3) | ⏳ Pending capture |
| **iPhone 6.5" Display Screenshots** | 1242 × 2688 px or 2688 × 1242 px (Min 3) | ⏳ Pending capture |
| **iPad Pro 12.9" Display Screenshots** | 2048 × 2732 px or 2732 × 2048 px (Min 3) | ⏳ Pending capture |
| **Privacy Policy URL** | Live HTTPS Web Page | ✅ Hosted on GitHub Pages |

---

## Technical Support Contact

* **Developer Email:** `mirmasum@mail.com`
* **Instagram:** `@mirmd_masum`
* **Discord:** `mir_masum`
* **GitHub Repository:** `https://github.com/MASUM79CSE/MINDVERSES`
