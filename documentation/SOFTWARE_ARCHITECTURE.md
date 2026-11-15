# MINDVERSE — Software Architecture Specification

**Document Version:** 1.0.0  
**Status:** Approved Architectural Baseline  
**Author:** Principal Software Engineer & Technical Lead  
**Last Updated:** 2026-11-15  

---

## 1. Architectural Philosophy & Principles

MINDVERSE is built on **Clean Architecture** principles structured in a **Feature-First** modular hierarchy. The core design mandates:

1. **Separation of Concerns:** Pure business logic and game rules are decoupled from UI rendering and Flutter widgets. Game rule engines operate deterministically without knowledge of Canvas, Widgets, or BuildContext.
2. **Local-First & Offline Resilience:** Persistent state lives locally with immediate read/write guarantees. Network or cloud services are strictly optional add-ons that do not block gameplay.
3. **Unidirectional Data Flow:** State is managed via **Riverpod 2.x** with immutable state models, explicit events, and isolated notifiers.
4. **Declarative Navigation:** Coordinated through **GoRouter** with typed routes, sub-routes for games, and strict backstack handling.
5. **Deterministic Game Simulation:** Puzzles execute on mathematical grids or physics steps, ensuring identical outputs given identical inputs (critical for unit testing and reproducible level validation).

---

## 2. System Architecture & Layering

```
┌────────────────────────────────────────────────────────┐
│                   Presentation Layer                   │
│   (Flutter Widgets, CustomPainters, Pages, Modals)    │
└───────────────────────────▲────────────────────────────┘
                            │ Reads State / Emits User Events
┌───────────────────────────┴────────────────────────────┐
│                    Application Layer                   │
│  (Riverpod Notifiers, State Holders, Navigation Logic) │
└───────────────────────────▲────────────────────────────┘
                            │ Invokes Domain Operations
┌───────────────────────────┴────────────────────────────┐
│                      Domain Layer                      │
│   (Pure Game Engines, Business Rules, Entities, Value  │
│         Objects, Scoring Calculators, Validators)      │
└───────────────────────────▲────────────────────────────┘
                            │ Interfaces / Contracts
┌───────────────────────────┴────────────────────────────┐
│                  Infrastructure Layer                  │
│    (Repositories, Local Storage / SQLite, Audio, Ads,  │
│               Haptics, Clock / System Services)        │
└────────────────────────────────────────────────────────┘
```

### 2.1 Layer Responsibilities

- **Presentation:** Renders UI, responds to gestures, delegates actions to notifiers. Contains no gameplay calculation algorithms.
- **Application:** Riverpod notifiers (`GameSessionNotifier`, `PlayerProfileNotifier`). Coordinates domain calls with persistence and updates UI state.
- **Domain:** Pure Dart libraries. Contains puzzle board state, pathfinding algorithms, adjacency solvers, move counters, and star-scoring equations. 100% testable without Flutter test framework dependencies.
- **Infrastructure:** Concrete implementations of repositories (e.g., `SaveGameRepositoryImpl`), local database engines, audio playback wrappers, and haptic feedback bridges.

---

## 3. Technology Stack & Package Selection Rationale

| Domain | Technology / Package | Architectural Rationale & Justification |
|---|---|---|
| **Framework** | Flutter 3.50.0 / Dart 3.14.0 | Official cross-platform SDK with first-class Android support, Skia/Impeller rendering pipeline, and high-performance Canvas APIs. |
| **State Management** | `flutter_riverpod: ^2.6.1` | Compile-time safety, testability without widget trees, no BuildContext coupling, granular reactivity avoiding broad rebuilds. |
| **Routing** | `go_router: ^14.8.1` | Declarative routing, deep linking, path-based routing, native Android back gesture compatibility, nested sub-routes. |
| **2D Physics** | `flame: ^1.24.0` & `flame_forge2d: ^0.18.0` (for Bridge Master) | Industry-standard Box2D port for Flutter. Provides deterministic rigid-body kinematics and constraint solvers for structural bridge mechanics. |
| **Custom Rendering** | Flutter `CustomPainter` / `Canvas` | Zero external dependency overhead for simulated 3D projection (Cube Logic, Perspective). Direct hardware-accelerated draw operations with matrix transformations. |
| **Local Persistence** | `shared_preferences: ^2.5.2` + JSON Schema Storage with SHA-256 Checksums | Ultra-lightweight, zero-native C++ compilation risk on Android 16/API 37 (avoiding native toolchain breakage like Isar binary incompatibility on bleeding-edge NDKs). Fully atomic file writes. |
| **Audio & Haptics** | `audioplayers: ^6.1.1` & `flutter/services.dart` (`HapticFeedback`) | Lightweight sound-effect playback, sound pooling, low latency, native system tactile response. |
| **Code Generation / Serialization** | `json_annotation` & `freezed_annotation` | Immutability, `copyWith`, exhaustive pattern matching, and type-safe JSON serialization. |

---

## 4. Directory Structure

```text
lib/
├── app/
│   ├── app.dart                   # Root MaterialApp widget & theme attachment
│   ├── router/
│   │   ├── app_router.dart        # GoRouter definitions & route guards
│   │   └── route_paths.dart       # Route string constants
│   ├── theme/
│   │   ├── app_colors.dart        # Palette: Dark, Deep Slate, Indigo, Amber, Jade
│   │   ├── app_typography.dart    # Hierarchy & font scales
│   │   └── app_theme.dart         # ThemeData builder (light & dark modes)
│   └── config/
│       └── app_constants.dart     # System-wide configuration constants
│
├── core/
│   ├── errors/                    # AppFailure, GameException, StorageException
│   ├── extensions/                # Context extensions, num formatting
│   ├── services/
│   │   ├── audio_service.dart     # Sound effects & background ambiance
│   │   └── haptic_service.dart    # Tactile feedback trigger
│   ├── storage/
│   │   ├── local_storage.dart     # Key-value & JSON file storage
│   │   └── storage_keys.dart      # Persistent storage keys
│   └── widgets/                   # AppButton, AppCard, GlassContainer, StarDisplay
│
├── features/
│   ├── home/                      # Hub screen, game cards, carousel
│   ├── game_selection/            # Game overview & level select grid
│   ├── profile/                   # Player statistics, avatar picker, badges
│   ├── progression/               # XP bar, level-up dialog, coin counter
│   ├── achievements/              # Achievement list, detail bottom sheet
│   ├── daily_challenge/           # Daily puzzle modal, streak indicator
│   └── settings/                  # Sound/haptic switches, privacy, credits
│
├── game_engines/
│   ├── common/                    # BasePuzzle, MoveResult, StarRating, PuzzleValidator
│   ├── cube_logic/                # 3D projection math, CubeFace, CubeEngine, 20 levels
│   ├── bridge_master/             # Node, Strut, StressEngine, Forge2D integration, 15 levels
│   ├── maze_architect/            # GridCell, MazePiece, PathFinder (A*), 15 levels
│   ├── gear_theory/               # Gear, RatioEngine, TransmissionValidator
│   ├── tiny_kingdom/              # HexTile, ResourceGrid, AdjacencyEvaluator
│   ├── perspective/               # ProjectionMatrix, OpticalAligner
│   └── memory_matrix/             # PatternSequence, TimedDistractor
│
└── shared/
    ├── models/                    # PlayerProfile, LevelResult, GameDefinition, Achievement
    ├── providers/                 # Global Riverpod providers (profileProvider, etc.)
    └── repositories/              # ProfileRepository, LevelProgressRepository
```

---

## 5. Game Engine Architecture Specifications

### 5.1 Cube Logic Engine (Simulated 3D Projection)
- **Mathematical Model:** Isometric/axonometric affine transformation matrix projecting a 3D coordinate $(x, y, z)$ into a 2D canvas point $(u, v)$:
  $$u = (x - z) \cdot \cos(\alpha) \cdot s + \text{cx}$$
  $$v = (x + z) \cdot \sin(\alpha) \cdot s - y \cdot s + \text{cy}$$
  where $\alpha = 30^\circ$, $s$ is scale factor, and $(\text{cx}, \text{cy})$ is viewport center.
- **State Representation:**
  - 3x3x3 or NxNxN cube composed of `CubeBlock` elements.
  - Each face holds an `EnergyNode` or `Conduit` with directional orientation (North, East, South, West).
- **Transformation Pipeline:**
  - Player drags rotate the bounding cube around X and Y axes via quaternions or Euler angles with damping interpolation (`TickerProvider`).
  - Face taps rotate the tapped block $90^\circ$ clockwise.
- **Validation:**
  - Graph traversal (Breadth-First Search) traces an uninterrupted energy conduit from `PowerSourceNode` to `TerminalNode`.
  - Level win triggered when all designated terminals are powered.

### 5.2 Bridge Master Engine (2D Kinematics & Physics)
- **Model:** Discrete structural analysis using Truss Mechanics integrated with Forge2D:
  - **Joints (Nodes):** Fixed anchor nodes and free construction nodes.
  - **Struts (Members):** Wood, Steel, Cable (varying weight, tensile strength, compression limit, and cost).
- **Simulation Loop:**
  1. *Build Mode:* Grid-snapped construction; enforces budget and material quantity limits.
  2. *Test Mode:* Spawn rigid bodies in Forge2D. Release a motorized vehicular load across the bridge deck.
  3. *Stress Calculation:* Calculate member strain $\epsilon = \frac{\Delta L}{L_0}$. If stress exceeds threshold $\sigma_{\text{max}}$, member snaps with visual/audio fracture.
- **Scoring:**
  - Star 1: Vehicle crosses successfully to the opposite bank.
  - Star 2: Bridge budget utilized $\le$ level target (e.g., $\le 80\%$).
  - Star 3: Maximum member stress remained $\le 65\%$ throughout crossing.

### 5.3 Maze Architect Engine (Deterministic Grid Puzzle)
- **Model:** $M \times N$ matrix where cells contain sliding path tiles (Straight, Corner, T-Junction, Cross, Dead-End, Fixed Wall).
- **Movement:** Similar to sliding block puzzles (orthogonal shifts along empty slots or rotary tile orientations).
- **Pathfinding & Verification:**
  - Real-time Bidirectional BFS/A* algorithm recalculates shortest open path between Start and Exit nodes upon every player move.
  - Solvability verifier checks parity and connectivity to prevent unresolvable dead-locks.
- **Scoring:**
  - Star 1: Path established and token successfully reaches Exit.
  - Star 2: Completed within $\le K$ moves.
  - Star 3: Completed without using the "Highlight Optimal Step" hint.

---

## 6. State Management Strategy (Riverpod 2.x)

### 6.1 State Hierarchy
```
Global Providers:
├── sharedPreferencesProvider (Synchronous instance via app initialization override)
├── localStorageServiceProvider
├── audioServiceProvider
└── hapticServiceProvider

Domain Repositories:
├── profileRepositoryProvider
└── levelProgressRepositoryProvider

Feature State Notifiers:
├── playerProfileNotifierProvider (AsyncNotifier<PlayerProfile>)
├── activeGameSessionNotifierProvider (FamilyNotifier<GameSessionState, GameType>)
└── dailyChallengeNotifierProvider (AsyncNotifier<DailyChallengeState>)
```

### 6.2 Immutable State Pattern
All states are defined as immutable classes with `@freezed` / `copyWith`. Mutations are processed strictly through pure state transitions inside notifiers:
```dart
state = state.copyWith(
  movesRemaining: state.movesRemaining - 1,
  board: newBoard,
  isSolved: hasWon,
);
```

---

## 7. Persistence & Data Integrity Strategy

1. **Storage Engine:** Structured JSON documents persisted to app sandbox document storage, paired with `SharedPreferences` for fast key-value lookups.
2. **Atomic Writes:** Saves write to a `.tmp` file and rename atomically, preventing corrupted states on unexpected app termination.
3. **Integrity Checksum:** Every save state bundle embeds a SHA-256 HMAC hash:
   $$\text{Checksum} = \text{HMAC-SHA256}(\text{JSON String}, \text{Salt})$$
   On load, any hash mismatch flags corrupted/modified local data and safely triggers auto-repair or backup restore.
4. **Schema Versioning:** Every entity embeds a `schemaVersion: int`. Migrations run synchronously in a migration pipeline on startup before UI mounts.

---

## 8. Performance & Rendering Guardrails

1. **Render Object Caching:** For CustomPainters (Cube Logic), static cube faces and lighting textures are pre-rendered to `ui.Picture` or cached `ui.Image` shaders to eliminate per-frame redraw bottlenecks.
2. **RepaintBoundaries:** All animated game canvases and simulated 3D viewports are isolated inside dedicated `RepaintBoundary` widgets.
3. **Zero Allocation in Game Loops:** Avoid instantiating objects (Vectors, Points, Paint instances) inside `paint(Canvas canvas, Size size)` methods. Reuse pooled allocations.
4. **Target Frame Rate:** Sustained 60 FPS; dynamic quality scaling drops particle density or shadow sampling if frame render time exceeds 14ms.
