# MINDVERSE — Changelog

All notable changes to the MINDVERSE project will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### [Phase 3] - 2026-11-21
#### Added
- Implemented Splash screen with brand scale and fade transitions, checking onboarding status.
- Implemented Onboarding flow with 3 interactive slides (THINK, SOLVE, EXPLORE), animated dot indicators, and skip/enter actions writing to `SharedPreferences`.
- Implemented HubScreen with top status bar (avatar, Level/XP progress bar, coin badge), quick navigation buttons, Daily Challenge hero card, 3 MVP mini-games (Cube Logic, Bridge Master, Maze Architect), and 4 expansion game cards.
- Implemented GameDetailScreen featuring 3-star scoring rules (Completion, Efficiency, Mastery), genre badges, level stats, and level select CTAs for all 7 games.
- Implemented LevelSelectScreen with campaign progress indicator, 4-column level grid, star rating displays, and interactive level preview dialogs.
- Implemented ProfileScreen with editable username dialog, avatar picker bottom sheet, Level/XP bar, and gameplay statistics.
- Implemented SettingsScreen with toggles for Sound Effects, Music Ambiance, and Haptics, segmented theme mode selector (Dark, Light, System), data privacy modal, and reset progress confirmation.
- Implemented reusable component and modal suite: `AppDialog`, `PauseModal`, `EmptyStateView`, `LoadingView`, `XpProgressBar`, `CoinBadge`.
- Configured smooth animated route transitions in `GoRouter` with `CustomTransitionPage`.
- Expanded automated test suite from 12 to 23 tests covering all shell screens, dialogs, modals, and edge cases with 0 static analysis issues.

### [Phase 2] - 2026-11-15
#### Added
- Initialized local Git repository and created baseline commit.
- Configured Android package identifier `com.mindverse.app` in `build.gradle.kts` and app label `MINDVERSE` in `AndroidManifest.xml`.
- Integrated dependencies: `flutter_riverpod: ^2.6.1`, `go_router: ^14.8.1`, `shared_preferences: ^2.5.2`, `crypto: ^3.0.6`, `uuid: ^4.5.1`.
- Built modular architecture across `app/`, `core/`, `features/`, `game_engines/`, `shared/`.
- Configured declarative navigation via GoRouter with typed route paths and sub-routes.
- Configured state management via Riverpod 2.x `ProviderScope` and synchronous SharedPreferences initialization.
- Built theme system supporting Dark and Light Material 3 modes with custom 2.5D palette and typography scale.
- Built core domain error models (`AppFailure`, `GameException`) and structured `LoggerService`.
- Built reusable UI component library (`AppButton`, `AppCard`, `GlassContainer`, `StarDisplay`).
- Installed Android NDK 28.2.13676358 via official Android CLI and compiled full debug Android APK (`app-debug.apk`, 154MB).
- Created unit and widget test suite (`test/unit/theme_test.dart`, `test/unit/error_models_test.dart`, `test/widget/ui_components_test.dart`, `test/widget_test.dart`) with 12/12 passing tests and 0 static analysis issues.

### [Phase 1] - 2026-11-15
#### Added
- Delivered complete technical design and requirements suite:
  - `documentation/PRODUCT_REQUIREMENTS.md`: 17 functional and 10 non-functional requirements.
  - `documentation/SOFTWARE_ARCHITECTURE.md`: Clean Architecture, Feature-First modularity, Riverpod 2.x, GoRouter, CustomPainter 3D projection, and local storage design.
  - `documentation/GAME_DESIGN_DOCUMENT.md`: Mechanics for all 7 mini-games, complete 50-level MVP design (20 Cube Logic, 15 Bridge Master, 15 Maze Architect), XP leveling curve ($150 \cdot L^{1.65}$), coin economy, hint system, audio/haptic design.
  - `documentation/DATABASE_DESIGN.md`: Full JSON schemas for PlayerProfile, LevelProgress, Achievements, CoinLedger, and UserSettings, with HMAC-SHA256 data integrity and schema versioning.
  - `documentation/DEVELOPMENT_ROADMAP.md`: Strict phase-gated execution plan for Phases 0 through 12.
  - `documentation/TECHNICAL_RISK_REGISTER.md`: 7 critical technical risks (TR-01 through TR-07) with concrete engineering mitigations.
  - `documentation/PHASE_REPORTS/PHASE_01.md`: Official Phase 1 completion report.

### [Phase 0] - 2026-11-15
#### Added
- Phase 0 diagnostic inspection completed.
- Initialized project technical documentation suite in `documentation/`:
  - `documentation/PHASE_REPORTS/PHASE_00.md`
  - `documentation/DEVELOPMENT_STATUS.md`
  - `documentation/CHANGELOG.md`
  - `documentation/KNOWN_ISSUES.md`
  - `documentation/DECISION_LOG.md`
- Verified Flutter 3.50.0 (stable), Dart 3.14.0, Android SDK 36/37, JDK 25, Git 2.56.0, and `Medium_Phone_API_37.0` AVD emulator.
- Verified existing project static analysis (`flutter analyze` with 0 issues) and widget tests (`flutter test` passing).
