# MINDVERSE — Product Requirements Document (PRD)

**Document Version:** 1.0.0  
**Status:** Approved for Implementation Baseline  
**Author:** Principal Software Engineer & Technical Lead  
**Last Updated:** 2026-11-15  

---

## 1. Executive Summary & Vision

**MINDVERSE** is a premium, unified mobile brain-and-strategy puzzle collection designed for iOS and Android (Android-first release). Rather than presenting a disjointed set of casual mini-apps, MINDVERSE delivers a cohesive gaming universe linked by:
- A shared progression system (XP, Coins, Player Levels).
- A unified three-star scoring framework.
- Global achievements and daily challenge cycles.
- A distinctive visual identity (2.5D / simulated 3D low-poly aesthetic, soft lighting, tactile feedback).
- A local-first, privacy-respecting architecture with optional cloud sync and rewarded monetization.

**Tagline:** Think. Solve. Explore.  
**Target Audience:** Puzzle enthusiasts, strategy fans, logic puzzle players, and casual gamers seeking intelligent, high-polish mental challenges.  
**Product Positioning:** "Brain Score" and performance metrics are internal game-progression indicators reflecting problem-solving skill, speed, and efficiency. They are explicitly NOT advertised as medical or scientific IQ scores.

---

## 2. Core Functional Requirements

### 2.1 Player Profile & Identity
- **FR-01 (Profile Creation):** On first launch, generate a local profile with default guest identity (editable username and selectable avatar).
- **FR-02 (Progression Metrics):** Track and display:
  - Total XP and current Player Level (calculated via logarithmic/polynomial XP curve).
  - Total Coins balance.
  - Overall Stars earned (summed across all games and levels).
  - Overall and per-game completion stats (total plays, win rate, best efficiency, hint usage).
  - Achievement badges unlocked.
- **FR-03 (Player Customization):** Allow changing username, avatar, and UI theme preferences (System/Light/Dark) in profile settings.

### 2.2 Game Hub & Navigation
- **FR-04 (Unified Hub):** Single central entry point showcasing all games as interactive 2.5D cards with progress indicators, star counts, and unlock states.
- **FR-05 (Game Detail View):** Dedicated overview screen for each game showing rules, mechanics summary, player statistics, and a "Play" / "Continue" CTA.
- **FR-06 (Level Selection Grid):** Pagination or scrollable grid displaying level numbers, star ratings (0–3 stars), locked/unlocked states, and best scores.
- **FR-07 (Pause & Session Controls):** In-game pause modal allowing Restart, Resume, Settings toggle (sound/haptics), and Exit to Level Select without corrupting game state.

### 2.3 Shared Economy & Scoring
- **FR-08 (Three-Star Scoring Criteria):**
  - **Star 1 (Completion):** Solving the level objective.
  - **Star 2 (Efficiency):** Solving within target moves, time, or budget constraints.
  - **Star 3 (Mastery/Skill):** Solving without using any hints or assistance.
- **FR-09 (XP Generation):**
  - Base XP for first-time completion of a level.
  - Bonus XP for earning Star 2 (efficiency) and Star 3 (skill).
  - Repeat plays grant reduced/nominal XP to prevent grinding exploits.
- **FR-10 (Coin Economy):**
  - Earned via first-time 3-star achievements, daily challenges, and optional rewarded ads.
  - Spent exclusively on optional in-game hints or cosmetic unlocks.
  - Ledger-backed transaction logging to prevent double-spend or negative balances.

### 2.4 Daily Challenges & Retention
- **FR-11 (Daily Challenge Generation):** Deterministic daily challenge selected based on UTC date hash, cycling across mini-games.
- **FR-12 (Daily Reset & Claim Protection):** Verified UTC-based reset. Prevents time-travel manipulation by recording last completed timestamp and hash.
- **FR-13 (Daily Streak):** Consecutive daily completions award increasing streak bonuses up to a 7-day cap.

### 2.5 Achievements
- **FR-14 (Event-Driven Achievements):** Triggered by verifiable domain events (e.g., `LevelCompletedEvent`, `PerfectScoreEvent`, `StreakUpdatedEvent`).
- **FR-15 (Tiered Badges):** Bronze, Silver, Gold tiers with dedicated art and XP/coin rewards.

### 2.6 Persistence & Offline-First
- **FR-16 (Zero-Latency Local Storage):** All game states, moves, unlocked levels, and profile data persist instantly to local database.
- **FR-17 (Full Offline Gameplay):** 100% of game levels, progression, and daily challenges (deterministic offline generator) functional without network connectivity.

---

## 3. Mini-Game Scope Definition

### 3.1 MVP Games (Initial Target: 50 Levels)
1. **Cube Logic (Priority: Highest)**
   - Levels: **20 playable levels**
   - Mechanics: 3D-simulated cube puzzle. Rotate view/faces, connect matching energy nodes, strict move budgets.
2. **Bridge Master**
   - Levels: **15 playable levels**
   - Mechanics: 2D physics structural bridge builder. Node-and-strut placement under budget, structural stress simulation, vehicular load testing.
3. **Maze Architect**
   - Levels: **15 playable levels**
   - Mechanics: Grid-based sliding maze tiles. Path manipulation, limited shifts, start-to-exit routing.

### 3.2 Post-MVP Games (Documented & Architecturally Prepared)
4. **Gear Theory:** Mechanical rotational gear trains with ratios, directional interlocks, and transmission loops.
5. **Tiny Kingdom:** Hex/grid-based adjacency strategy, balancing agricultural, residential, and industrial resource synergies.
6. **Perspective:** Non-Euclidean optical alignment puzzles utilizing camera rotation and forced perspective projections.
7. **Memory Matrix:** High-speed sequential spatial memory patterns with distraction intervals and reverse playback modes.

---

## 4. Non-Functional Requirements (NFR)

### 4.1 Performance & Rendering
- **NFR-01 (Frame Rate):** Maintain sustained 60 FPS on mid-range Android devices (e.g., Snapdragon 600/700 series, Helio G-series). Graceful 30 FPS floor on low-end hardware.
- **NFR-02 (Cold Start):** Time-to-interactive under 2.0 seconds from app launch to Hub on target devices.
- **NFR-03 (Memory Footprint):** Peak runtime memory under 180MB RAM on Android. No asset-loading spikes causing GC stutter.
- **NFR-04 (Frame Budget):** UI rebuilds and render loops must complete within a 16.6ms frame budget (CustomPainter caching, minimal widget rebuilds).

### 4.2 Security & Integrity
- **NFR-05 (Anti-Tampering):** Local save files integrity-checked (SHA-256 checksum verification on deserialized save payloads).
- **NFR-06 (No Plaintext Secrets):** API keys, ad unit IDs, and configuration secrets injected at build time via Dart environment defines (`--dart-define`).
- **NFR-07 (Privacy Compliance):** Full compliance with Google Play Data Safety, GDPR, and COPPA. Zero non-essential telemetry collection. Explicit user consent prior to analytics/ads initialization.

### 4.3 Platform Support & Responsiveness
- **NFR-08 (Target SDKs):** `minSdkVersion: 24` (Android 7.0 Nougat), `targetSdkVersion: 36` (Android 16), `compileSdkVersion: 36`.
- **NFR-09 (Screen Adaptability):** Responsive layouts supporting aspect ratios from 16:9 to 21:9, tablets, foldables, and display cutouts/notches using SafeArea and MediaQuery.
- **NFR-10 (Predictive Back & Gestures):** Full integration with modern Android edge-to-edge system navigation and back gestures.
