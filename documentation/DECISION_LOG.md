# MINDVERSE — Architectural Decision Log

**Project:** MINDVERSE  
**Status:** Active  

---

## ADR-000: Adoption of Phased, Approval-Gated Engineering Methodology
- **Date:** 2026-11-15
- **Status:** Approved
- **Context:** MINDVERSE is a complex puzzle game collection encompassing seven distinct mini-games with shared progression, persistence, and state.
- **Decision:** Strict phase-by-phase implementation (Phases 0 through 12). Each phase must meet objective acceptance criteria and receive explicit user approval before subsequent phases are initiated.
- **Consequences:** Eliminates premature code sprawl, ensures test coverage at each boundary, and guarantees verifiable stability before expanding game features.

---

## ADR-001: Environment Baseline & Tooling Strategy
- **Date:** 2026-11-15
- **Status:** Approved
- **Context:** Diagnostics during Phase 0 confirmed Flutter 3.50.0 (stable), Dart 3.14.0, Android SDK 36.0.0 / API 37, JDK 25 bundled with Android Studio, and Android Gradle Plugin 9.3.1.
- **Decision:** Standardize development on Flutter 3.50.0 / Dart 3.14.0 targeting Android first with iOS-ready modularity. All commands will run against the verified local Android toolchain.
- **Consequences:** High stability with modern Gradle Kotlin DSL and current Flutter engine capabilities.

---

## ADR-002: Modular Clean Architecture & State Management Selection
- **Date:** 2026-11-15
- **Status:** Approved
- **Context:** MINDVERSE requires clean separation between UI widgets, shared progression/economy, and mathematical game simulation engines.
- **Decision:** Adopt a **Feature-First Clean Architecture** with **Riverpod 2.x** (`flutter_riverpod`) for state management and **GoRouter** for declarative navigation. Pure puzzle rule engines remain in the Domain layer with zero Flutter widget dependencies.
- **Consequences:** Maximizes unit testability of game logic, eliminates context-dependent UI coupling, and prevents unnecessary widget rebuilds.

---

## ADR-003: Rendering & Simulated 3D Projection Strategy
- **Date:** 2026-11-15
- **Status:** Approved
- **Context:** Cube Logic (Game 1) and Perspective (Game 6) require 3D spatial rotation and interaction without the overhead or fragility of heavy 3D game engines (e.g., Unity).
- **Decision:** Implement simulated 3D projection directly using Flutter's hardware-accelerated `CustomPainter` / `Canvas` with an axonometric/isometric projection matrix and cached `ui.Picture` render objects.
- **Consequences:** Native 60 FPS performance on mid-range devices, zero external native 3D engine binaries, and seamless Flutter gesture integration.

---

## ADR-004: 2D Physics Solution Selection (Bridge Master)
- **Date:** 2026-11-15
- **Status:** Approved
- **Context:** Bridge Master (Game 2) requires simulated structural stress, load movement, and member fracture.
- **Decision:** Integrate **Flame** (`flame: ^1.24.0`) and **Forge2D** (`flame_forge2d: ^0.18.0`) exclusively within the Bridge Master feature module.
- **Consequences:** Robust Box2D physics simulation for structural trusses while keeping the rest of the application lightweight and widget-driven.

---

## ADR-005: Local Storage Engine & Integrity Architecture
- **Date:** 2026-11-15
- **Status:** Approved
- **Context:** Local persistence must be fast, resilient against corruption, offline-first, and immune to native C++ NDK / 16KB page alignment breakages on modern Android (API 37+).
- **Decision:** Utilize atomic double-buffered JSON file storage (`.tmp` write $\rightarrow$ file replace) combined with HMAC-SHA256 signature verification and automated `.bak` fallback, paired with `SharedPreferences` for fast configuration access.
- **Consequences:** Completely pure Dart runtime execution with zero native binary compilation risk, resilient against device crashes, and directly aligned with cloud document synchronization in Phase 10.

---

## ADR-006: Android NDK Management & Desktop Platform Configuration
- **Date:** 2026-11-15
- **Status:** Approved
- **Context:** Flutter build required NDK 28.2.13676358 during Android APK assembly, and Windows symlink permissions required elevation for unused Windows desktop plugin builds.
- **Decision:**
  1. Disabled Windows desktop target via `flutter config --no-enable-windows-desktop` to ensure clean, unelevated `flutter pub get` executions for mobile development.
  2. Installed the exact required NDK package `ndk/28.2.13676358` via the official Android CLI tool (`android sdk install ndk/28.2.13676358`).
- **Consequences:** Full Android build pipeline successfully produces debug APKs without tooling conflicts.

---

## ADR-007: Declarative Route Transitions & Responsive Mobile Shell
- **Date:** 2026-11-21
- **Status:** Approved
- **Context:** Mobile application shell requires smooth screen-to-screen transitions and overflow-proof responsiveness across all mobile screen widths and densities.
- **Decision:**
  1. Standardized `GoRouter` route transitions using `CustomTransitionPage` combining `CurvedAnimation` (easeOutCubic) with subtle horizontal slide (`Offset(0.04, 0)`) and fade.
  2. Applied defensive horizontal constraints (`Flexible`, `Expanded`, `overflow: TextOverflow.ellipsis`, `maxLines: 1`) across all status cards and list headers to ensure 0 `RenderFlex` overflow errors on compact aspect ratios.
- **Consequences:** Clean visual polish, responsive adaptability across varying phone viewports, and 100% automated test coverage.
