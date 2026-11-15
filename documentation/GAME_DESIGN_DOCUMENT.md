# MINDVERSE — Game Design Document (GDD)

**Document Version:** 1.0.0  
**Status:** Approved Game Design Specification  
**Author:** Principal Software Engineer & Technical Lead  
**Last Updated:** 2026-11-15  

---

## 1. Game Design Vision & Player Journey

MINDVERSE is built around the feeling of **"Intellectual Flow"** — the rewarding sensation of dissecting a complex spatial, mechanical, or logical puzzle, discovering an elegant pattern, and executing the solution.

### Core Pillars
1. **Clarity of Rules:** A player should comprehend the basic mechanics of any game within 15 seconds without reading paragraphs of text.
2. **Deterministic Fairness:** No RNG-based puzzle failures. Every victory or failure is 100% the outcome of player choices.
3. **Escalating Elegance:** Early levels teach core mechanics through tactile discovery; later levels combine disparate rules into harmonious brain teasers.
4. **Tactile Feedback:** Crisp audio cues, haptic clicks, and smooth interpolated animations give simulated physical weight to digital puzzles.

---

## 2. Detailed Mini-Game Mechanics

---

### GAME 1: CUBE LOGIC (MVP Priority: Highest — 20 Levels)

#### Concept
The player manipulates an isometric, simulated-3D cube structure to channel glowing energy conduits from one or more Power Sources to matching Terminal Nodes.

#### Mechanics & Controls
- **3D Orbit:** Dragging outside the active face smoothly rotates the entire cube structure in 3D space, revealing all 6 faces.
- **Face Manipulation:** Tapping an interactive block on the front-facing plane rotates the block $90^\circ$ clockwise, repositioning its internal conduit paths.
- **Conduit Types:**
  - *Straight:* Connects opposite edges (North-South or East-West).
  - *Corner:* Connects adjacent edges (North-East, East-South, etc.).
  - *Cross:* Two independent non-intersecting channels (North-South and East-West).
  - *T-Junction:* Splits power into two directions.
  - *Polarized Node:* Allows energy flow only if the color of the conduit matches the node frequency (introduced at Level 10).
  - *Locked Block:* Fixed in place; cannot be rotated (acts as an environmental constraint).
- **Move Budget:** Each level defines a maximum move count $M$. Exceeding $M$ results in an Energy Depletion failure.

#### Scoring Rules
- **Star 1 (Completion):** All terminal nodes receive active energy flow.
- **Star 2 (Efficiency):** Solved within $\le M_{\text{target}}$ moves (where $M_{\text{target}} \le M$).
- **Star 3 (Mastery):** Solved without using the "Pulse Trace" hint.

#### 20-Level Progression Curve
| Level | Board Size | Power / Terminals | Block Types Introduced | Max Moves | Target Moves (Star 2) |
|---|---|---|---|---|---|
| **1** | 2x2x1 | 1 Source / 1 Terminal | Straight, Corner | 6 | 3 |
| **2** | 2x2x1 | 1 Source / 1 Terminal | Corners only | 8 | 4 |
| **3** | 2x2x2 | 1 Source / 1 Terminal | Straight, Corner, 1 Locked | 10 | 6 |
| **4** | 2x2x2 | 1 Source / 2 Terminals | Split paths | 12 | 7 |
| **5** | 3x3x1 | 1 Source / 1 Terminal | Cross conduits | 12 | 8 |
| **6** | 3x3x1 | 1 Source / 2 Terminals | T-Junctions | 14 | 9 |
| **7** | 3x3x2 | 1 Source / 2 Terminals | 2 Locked blocks | 16 | 10 |
| **8** | 3x3x2 | 2 Sources / 2 Terminals | Dual isolated circuits | 18 | 12 |
| **9** | 3x3x3 | 1 Source / 1 Terminal | Full 3D orbital pathing | 20 | 12 |
| **10** | 3x3x3 | 2 Sources / 2 Terminals | Color-coded conduits (Cyan/Amber) | 22 | 14 |
| **11** | 3x3x3 | 2 Sources / 3 Terminals | Color crossovers | 22 | 15 |
| **12** | 3x3x3 | 2 Sources / 2 Terminals | 4 Locked constraint blocks | 24 | 16 |
| **13** | 3x3x3 | 3 Sources / 3 Terminals | Multi-colored energy routing | 25 | 17 |
| **14** | 4x4x1 | 2 Sources / 2 Terminals | Large planar matrix | 24 | 16 |
| **15** | 4x4x2 | 2 Sources / 3 Terminals | Dual-plane depth wrapping | 26 | 18 |
| **16** | 4x4x2 | 3 Sources / 3 Terminals | High density routing | 28 | 19 |
| **17** | 3x3x3 | 2 Sources / 4 Terminals | Dual-frequency splitters | 28 | 20 |
| **18** | 4x4x3 | 3 Sources / 4 Terminals | 6 Locked obstacles | 30 | 22 |
| **19** | 4x4x3 | 3 Sources / 4 Terminals | High complexity 3D wrap | 32 | 23 |
| **20 (Master)** | 4x4x4 | 4 Sources / 4 Terminals | Complete 3D multi-frequency matrix | 35 | 24 |

---

### GAME 2: BRIDGE MASTER (MVP Priority: High — 15 Levels)

#### Concept
The player designs and constructs load-bearing bridges across river valleys, ravines, and industrial chasms within a strict budget, testing structural integrity under live vehicular weight.

#### Mechanics & Controls
- **Build Mode (2D Grid View):**
  - Tap and drag between anchor nodes to place structural members.
  - Materials:
    - *Wood Strut:* Low cost ($100), moderate tensile and compression resistance.
    - *Steel Beam:* High cost ($350), extreme tensile and compression resistance.
    - *Steel Cable:* Moderate cost ($200), high tensile resistance, ZERO compression resistance (slackens).
    - *Road Deck:* Fixed cost ($150), required for vehicle transit.
- **Simulation Mode (Live Physics):**
  - Tap "Simulate". Physics engine (Forge2D) initializes gravity and mass.
  - A vehicle (Scooter, Delivery Van, Heavy Cargo Truck) drives across the deck.
  - Member stresses are visualized in real-time via color gradients (Green $\rightarrow$ Yellow $\rightarrow$ Red).
  - If stress on any member exceeds $100\%$, it fractures. If the vehicle falls below the failure threshold line, level fails.

#### Scoring Rules
- **Star 1 (Completion):** Vehicle successfully reaches the destination flag.
- **Star 2 (Budget Efficiency):** Total build cost $\le \text{Budget Target}$ (e.g., $\le 75\%$ of max budget).
- **Star 3 (Engineering Mastery):** Maximum peak stress across all members during transit $\le 70\%$.

#### 15-Level Progression Curve
| Level | Gap Distance | Vehicle Type | Materials Available | Max Budget | Star 2 Budget Target |
|---|---|---|---|---|---|
| **1** | 6 meters | Light Buggy (800kg) | Road, Wood | $1,500 | $1,100 |
| **2** | 8 meters | Light Buggy (800kg) | Road, Wood | $2,000 | $1,450 |
| **3** | 10 meters | Delivery Van (1,800kg) | Road, Wood | $2,800 | $2,100 |
| **4** | 12 meters | Delivery Van (1,800kg) | Road, Wood, Cable | $3,500 | $2,600 |
| **5** | 10 meters (Central Pier) | Delivery Van (1,800kg) | Road, Wood, Cable | $3,200 | $2,400 |
| **6** | 14 meters | Heavy Truck (4,200kg) | Road, Wood, Steel | $4,500 | $3,400 |
| **7** | 16 meters | Heavy Truck (4,200kg) | Road, Wood, Steel, Cable | $5,500 | $4,100 |
| **8** | 12 meters (Inclined Valley) | Delivery Van (1,800kg) | Road, Wood, Steel | $4,200 | $3,100 |
| **9** | 18 meters (Deep Ravine) | Heavy Truck (4,200kg) | Road, Wood, Steel, Cable | $6,500 | $4,800 |
| **10** | 14 meters | Double Vehicle Convoy | Road, Wood, Steel | $5,800 | $4,300 |
| **11** | 20 meters (Arch Required) | Heavy Truck (4,200kg) | Road, Steel, Cable | $7,500 | $5,500 |
| **12** | 16 meters (High Wind Shear) | Heavy Truck (4,200kg) | Road, Wood, Steel, Cable | $6,800 | $5,000 |
| **13** | 22 meters (Twin Chasm) | Heavy Truck (4,200kg) | Road, Wood, Steel, Cable | $8,500 | $6,200 |
| **14** | 20 meters (Uneven Anchors) | Heavy Cargo Hauler (6,000kg) | Road, Steel, Cable | $8,800 | $6,500 |
| **15 (Master)** | 24 meters (Mega Span) | Heavy Cargo Hauler (6,000kg) | All Materials | $10,000 | $7,400 |

---

### GAME 3: MAZE ARCHITECT (MVP Priority: High — 15 Levels)

#### Concept
The player rearranges modular sliding grid tiles containing walls, pathways, and switches to construct an unblocked navigable route from a Starting Portal to an Exit Gateway.

#### Mechanics & Controls
- **Grid Layout:** $3 \times 3$, $4 \times 4$, or $5 \times 5$ grid of tiles with 1 or more empty slots (sliding block mechanic) or rotary shift lanes.
- **Controls:** Swipe to slide an adjacent tile into the open slot.
- **Interactive Elements:**
  - *Key & Gate Tiles:* Moving through a Key tile unlocks matching colored Gates.
  - *Pressure Plate:* Steps that rotate a remote tile $90^\circ$.
  - *One-Way Directional Tiles:* Path can only be traversed in the indicated arrow direction.
  - *Fixed Obstacle Tiles:* Immovable granite pillars that cannot slide.

#### Scoring Rules
- **Star 1 (Completion):** Valid continuous path from Start to Exit created and traversed by the Explorer token.
- **Star 2 (Move Efficiency):** Completed within $\le M_{\text{target}}$ slides.
- **Star 3 (Mastery):** Completed without using the "Pathfinder Optimal Move" hint.

#### 15-Level Progression Curve
| Level | Grid Size | Special Elements | Move Limit | Star 2 Move Target |
|---|---|---|---|---|
| **1** | 3x3 | Straight & Corner paths | 10 | 4 |
| **2** | 3x3 | 1 Dead-end obstacle | 12 | 6 |
| **3** | 3x3 | 1 Fixed granite block | 14 | 8 |
| **4** | 3x3 | Blue Key & Blue Gate | 16 | 10 |
| **5** | 4x4 | Open pathways | 18 | 11 |
| **6** | 4x4 | 2 Fixed obstacles | 20 | 12 |
| **7** | 4x4 | One-Way arrow paths | 22 | 14 |
| **8** | 4x4 | Red & Blue Keys/Gates | 24 | 15 |
| **9** | 4x4 | Rotating Pressure Plate | 26 | 17 |
| **10** | 4x4 | Dual Exits (Any valid) | 28 | 18 |
| **11** | 5x5 | Large scale labyrinth | 30 | 20 |
| **12** | 5x5 | 3 Keys / Gates sequence | 32 | 22 |
| **13** | 5x5 | 2 Rotating plates + 2 Keys | 34 | 24 |
| **14** | 5x5 | Dual One-Way interlocks | 36 | 25 |
| **15 (Master)** | 5x5 | Full multi-gate kinetic labyrinth | 40 | 27 |

---

### GAMES 4–7: ARCHITECTURAL SPECIFICATION (Post-MVP)

#### Game 4: Gear Theory
- **Concept:** Mechanical gear mesh solver. Place gears of varying radii ($R=1, 2, 3$) onto pegs to transmit rotational energy from a Motor Gear to a Destination Flywheel at a required RPM and direction (Clockwise vs. Counter-Clockwise).
- **Core Math:** Angular velocity transmission $\omega_2 = -\omega_1 \cdot \frac{r_1}{r_2}$.

#### Game 5: Tiny Kingdom
- **Concept:** Strategic tile-placement settlement builder. Place limited hex tiles (Forest, Farm, Mountain, Castle, Village, Market) on a grid to maximize adjacency score points under level objectives.
- **Synergies:** Farm (+2 near Water, -1 near Mountain); Village (+3 near Farm & Forest); Market (+4 near 2+ Villages).

#### Game 6: Perspective
- **Concept:** Optical alignment and forced perspective. 3D geometric fragments floating in space appear disjointed until the user rotates the viewport camera to an exact parallax angle where silhouettes visually merge to form a complete target symbol.

#### Game 7: Memory Matrix
- **Concept:** Spatial memory and cognitive pattern recall. A grid flashes a rhythmic sequence of glowing nodes. The player must accurately reproduce the sequence. Advanced tiers introduce temporal delay, distractor flashes, and reverse sequence playback.

---

## 3. Progression, Economy & Scoring Systems

### 3.1 XP Curve & Player Levels
Player Level $L$ is calculated from Total XP via an exponential curve:
$$\text{XP}_{\text{required}}(L) = 150 \cdot L^{1.65}$$

| Level | Cumulative XP Required | Level Name / Title |
|---|---|---|
| **1** | 0 | Novice Thinker |
| **2** | 150 | Curious Mind |
| **3** | 475 | Apprentice Solver |
| **4** | 980 | Strategic Mind |
| **5** | 1,670 | Logic Adept |
| **10** | 7,450 | Master Architect |
| **20** | 29,800 | Grandmaster Strategist |

### 3.2 XP Rewards per Level Completion
- **First-Time Completion (Star 1):** +100 XP
- **First-Time Efficiency (Star 2):** +50 XP
- **First-Time Mastery/No-Hint (Star 3):** +50 XP
- **Subsequent Replays:** +10 XP (flat anti-grind rate)

### 3.3 Coin Economy
- **Earn Rate:**
  - 3-Star Level Completion: +25 Coins
  - Daily Challenge Completion: +100 Coins
  - Achievement Unlock: +50 to +250 Coins
  - Optional Rewarded Ad: +75 Coins
- **Sink (Expenditure):**
  - In-Game Hint (Single Step): 30 Coins
  - Full Solution Blueprint / Auto-Trace: 100 Coins
  - Player Profile Avatars / Cosmetics: 500 – 2,000 Coins

---

## 4. Audio & Haptic Design

- **Cube Logic:** Deep wooden mechanical click on rotation; soft electrical chime on node connection; energetic crescendo harmonic cord upon level completion.
- **Bridge Master:** Tension creak audio scaling in frequency as stress approaches $90\%$; sharp snap sound on member fracture; celebratory vehicle horn on reaching the goal.
- **Maze Architect:** Stone tile sliding friction sound; stone click lock on grid snap; gate lowering chime on key collection.
- **Haptics:**
  - Standard tap / move: `HapticFeedback.selectionClick()`
  - Snapping into place: `HapticFeedback.mediumImpact()`
  - Structural fracture / invalid move: `HapticFeedback.heavyImpact()`
  - Level victory: `HapticFeedback.vibrate()` (success pattern)
