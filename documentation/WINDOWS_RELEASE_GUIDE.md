# MINDVERSE — Windows Desktop Release & Packaging Guide

Step-by-step instructions for building, testing, and packaging MINDVERSE for Windows (Windows 10 / 11 x64).

---

## Prerequisites

- [ ] Windows 10 or 11 (64-bit)
- [ ] Flutter SDK (v3.14.0+) installed and configured in PATH
- [ ] Visual Studio 2022 (or 2019) with **Desktop development with C++** workload installed (required for Windows native compilation via CMake / MSVC)

---

## Step 1: Verify Windows Environment

Open your terminal in the project root and verify Windows desktop support:

```bash
flutter doctor
```
Ensure Visual Studio and Windows toolchain checkmarks are green.

---

## Step 2: Test Run on Windows

To run the app locally in debug mode on Windows:

```bash
flutter run -d windows
```

---

## Step 3: Build Windows Release Executable

To compile a highly optimized release build:

```bash
flutter build windows --release
```

* **Build Output Directory:** `build/windows/x64/runner/release/`
* **Main Executable:** `mindverse.exe`

The release folder contains:
* `mindverse.exe` (compiled C++ runner with Flutter engine)
* `data/` (Flutter assets, fonts, and compiled Dart snapshot)
* DLL dependencies (`flutter_windows.dll`, plugin DLLs).

---

## Step 4: Package for Distribution (.zip)

To create a portable distribution archive:

1. Navigate to `build/windows/x64/runner/release/`.
2. Select all files and compress them into a `.zip` archive named `MINDVERSE-Windows-x64-v1.0.0.zip`.
3. Users can extract the ZIP and run `mindverse.exe` directly without installation.

---

## Step 5: Optional — Create Windows Installer (.msi / .exe setup)

If you want an installer wizard (Setup.exe):
1. Download [Inno Setup](https://jrsoftware.org/isinfo.php).
2. Create an Inno Setup script (`setup.iss`) pointing to `build/windows/x64/runner/release/` files.
3. Compile the script to generate `MINDVERSE-Setup-1.0.0.exe`.
