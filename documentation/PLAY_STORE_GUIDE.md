# MINDVERSE — Play Store Preparation Guide

Step-by-step instructions for publishing MINDVERSE on Google Play.

## Prerequisites

- [ ] Google Play Developer account ($25 one-time fee)
- [ ] Physical address for developer contact (required by Google Play)
- [ ] Privacy policy hosted on a publicly accessible URL
- [ ] Release-signed APK/AAB
- [ ] App icon and screenshots

## Step 1: Create Google Play Developer Account

1. Go to https://play.google.com/console
2. Sign in with your Google account
3. Pay the $25 one-time registration fee
4. Complete the developer profile:
   - Developer name: "Mir Md. Masum"
   - Developer email: mirmasum@mail.com
   - Developer address: (Your physical address)
   - Contact phone: (Optional)
   - Contact website: (Optional)

## Step 2: Create New App

1. In Play Console, click "Create app"
2. Select "Game" as the type
3. Enter app name: "MINDVERSE: Brain Puzzles"
4. Select "Free" as the pricing
5. Click "Create app"

## Step 3: Complete Store Listing

Copy the content from `PLAY_STORE_LISTING.md` into the corresponding fields:

1. **Main store listing:**
   - Title: "MINDVERSE: Brain Puzzles"
   - Short description: (from PLAY_STORE_LISTING.md)
   - Full description: (from PLAY_STORE_LISTING.md)
   - Category: Puzzle
   - App icon: (512×512 px PNG)
   - Feature graphic: (1024×500 px PNG)
   - Screenshots: (At least 2 phone screenshots)

2. **Contact information:**
   - Email: mirmasum@mail.com
   - Website: (Optional)
   - Privacy policy: (Hosted URL)

## Step 4: Complete Data Safety Declaration

Follow `DATA_SAFETY.md` to complete the Data Safety section:

1. Navigate to Setup → Data Safety
2. Select "No" for data collection
3. Confirm no data is shared
4. Save and publish

## Step 5: Complete Content Rating

1. Navigate to Setup → Content rating
2. Complete the questionnaire:
   - Violence & Gore: None
   - Drug Reference: None
   - Alcohol Reference: None
   - Sexual Content: None
   - Profanity: None
   - Hate Speech: None
   - Legal: None
3. Submit for rating (rated "Everyone")

## Step 6: Set Up In-App Products (Optional)

If you want to offer in-app purchases:

1. Navigate to Monetize → In-app products
2. Create product types:
   - Managed products (one-time purchases)
   - Subscriptions (if applicable)
3. Configure product details:
   - Product ID
   - Title
   - Description
   - Price
4. Link products to your app code via Google Play Billing Library

**Note:** Google Play Billing Library integration is not yet implemented in the app. This is a future enhancement.

## Step 7: Create Release

1. Navigate to Release → Setup → App bundles
2. Upload your signed APK/AAB
3. Wait for processing and pre-launch report
4. Review the pre-launch report for any issues

## Step 8: Create Release Track

1. Navigate to Release → Production
2. Create a new release
3. Add your APK/AAB
4. Write release notes:
   ```
   Welcome to MINDVERSE!

   • 7 unique puzzle games
   • 90 challenging levels
   • Daily challenges
   • Achievement system
   • Play completely offline

   Thank you for downloading!
   ```
5. Review the release
6. Click "Review release" then "Publish release"

## Step 9: Post-Publication

1. Monitor the Pre-launch report for crash reports and test results
2. Check the Vital section for app health metrics
3. Respond to user reviews
4. Plan updates based on user feedback

## Required Assets Checklist

| Asset | Size | Format | Status |
|-------|------|--------|--------|
| App icon | 512×512 px | PNG | ❌ Not created |
| Feature graphic | 1024×500 px | PNG/JPG | ❌ Not created |
| Phone screenshots | 320-3840 px | PNG/JPG | ❌ Not captured |
| Promotional video | 720p+ | MP4/MOV | ⏹ Optional |

## Documentation Checklist

| Document | Status |
|----------|--------|
| Privacy policy | ✅ Created (`PRIVACY_POLICY.md`) |
| Data Safety guide | ✅ Created (`DATA_SAFETY.md`) |
| Store listing content | ✅ Created (`PLAY_STORE_LISTING.md`) |
| Privacy policy URL | ❌ Not hosted |

## Next Steps

1. **Host privacy policy:** Upload `PRIVACY_POLICY.md` to a public URL (GitHub Pages, Google Sites, etc.)
2. **Create graphics:** Design app icon, feature graphic, and capture screenshots
3. **Build release:** Add Windows Security exclusion and build signed release APK
4. **Create Play Console account:** Register as a Google Play developer
5. **Complete listing:** Copy content from `PLAY_STORE_LISTING.md` to Play Console
6. **Upload and publish:** Follow steps 7-8 above

## Important Notes

- **Privacy policy URL:** Google Play requires a publicly accessible privacy policy. Host the `PRIVACY_POLICY.md` content on any web service.
- **Physical address:** Google Play requires a physical address for the developer contact. Provide this in Play Console.
- **In-app purchases:** The app currently does not implement Google Play Billing Library. If you want to offer IAPs, this needs to be implemented first.
- **Release signing:** The keystore is configured but the release build verification is pending due to Windows Security policy. Add the Flutter SDK directory to Windows Security exclusions to complete the build.
