# MINDVERSE — Technical Risk Register & Mitigation Strategy

**Document Version:** 1.0.0  
**Status:** Approved Risk Strategy  
**Author:** Principal Software Engineer & Technical Lead  
**Last Updated:** 2026-11-15  

---

## 1. Risk Evaluation Matrix

| Risk ID | Category | Severity | Probability | Impact | Description | Mitigation Strategy |
|---|---|---|---|---|---|---|
| **TR-01** | Rendering / Performance | **High** | Medium | High | Simulated 3D projection in Cube Logic and Perspective could cause frame drops / CPU throttling on low-end devices during continuous rotation. | Use pre-baked `ui.Picture` caches for static block faces; decouple interaction drag calculations from drawing loops; isolate canvas in a dedicated `RepaintBoundary`; dynamically disable shadow antialiasing if frame time exceeds 14ms. |
| **TR-02** | Physics / Determinism | **High** | Medium | High | 2D physics simulation (Forge2D) in Bridge Master could yield non-deterministic results across ARM vs. x86_64 CPU architectures due to floating-point differences. | Enforce fixed-timestep physics updates (`step(1/60)`); clamp maximum substeps; avoid cumulative floating-point dependencies for win conditions; validate win via vehicle endpoint bounds rather than exact coordinate velocities. |
| **TR-03** | Persistence / Integrity | **High** | Low | High | App crash, OS task kill, or battery outage during file write could corrupt the JSON save file, destroying player progress. | Implement atomic double-buffered writes: writes go to `.tmp` file, flushed to disk, then atomically renamed to target file. Embed SHA-256 HMAC checksums and keep an automated `.bak` copy. |
| **TR-04** | Security / Cheat Abuse | **Medium** | High | Medium | Players alter device clock to manipulate daily challenges or repeatedly claim daily login streaks. | Daily challenge generator derives puzzle index from UTC date hash, not local time. Save state records monotonic timestamps (`DateTime.now().toUtc()`) and rejects any completion timestamp earlier than the last recorded event. |
| **TR-05** | Native NDK / Compatibility | **High** | Low | High | Future Android OS versions (Android 15/16) enforce 16KB memory page alignment, which breaks unmaintained native C++ plugins (e.g., older SQLite or Isar binaries). | Rely primarily on pure Dart implementations and official Flutter engine bindings. Select packages with verified 16KB page support and active maintenance. |
| **TR-06** | Memory / Lifecycle | **Medium** | Medium | Medium | Game engine state holders, physics worlds, or audio players could leak memory when switching rapidly between levels in the Hub. | Explicitly implement `dispose()` lifecycle hooks on all controllers, audio pools, and Flame game worlds. Riverpod `autoDispose` used for level session providers. |
| **TR-07** | Monetization / Ad Failure | **Medium** | High | Low | Rewarded ad fails to load due to offline state or ad network error, preventing player from getting hints. | Core game design ensures every level is 100% solvable without hints. Hints can also be purchased with earned gameplay coins; ads are strictly optional multipliers. |
