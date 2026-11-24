# MINDVERSE — macOS Desktop Release & Packaging Guide

Step-by-step instructions for building, signing, and packaging MINDVERSE for macOS (Apple Silicon & Intel).

---

## Prerequisites

- [ ] macOS host running Ventura (13.0) or later
- [ ] Xcode (v15+) installed with Command Line Tools
- [ ] Flutter SDK installed and configured in PATH
- [ ] Apple Developer Account (for code signing & notarization)

---

## Step 1: Test Run on macOS

To run the app locally in debug mode on macOS:

```bash
flutter run -d macos
```

---

## Step 2: Build macOS Release Application Bundle (.app)

Open your terminal in the project root and run:

```bash
flutter build macos --release
```

* **Build Output Directory:** `build/macos/Build/Products/Release/`
* **App Bundle:** `MINDVERSE.app`

---

## Step 3: Code Signing & Entitlements

1. Open `macos/Runner.xcodeproj` in Xcode.
2. Select the **Runner** target → **Signing & Capabilities**.
3. Choose your Apple Developer **Team**.
4. Ensure entitlements (`Release.entitlements`) are correctly applied for sandboxing and app review compliance.

---

## Step 4: Package as DMG or ZIP for Distribution

To distribute the macOS app:

1. **Create a ZIP archive:**
   ```bash
   cd build/macos/Build/Products/Release/
   zip -r MINDVERSE-macOS-Universal.zip MINDVERSE.app
   ```
2. **Create a DMG installer (Optional):**
   Use tools like `create-dmg` to bundle `MINDVERSE.app` into a drag-and-drop installer disk image.
