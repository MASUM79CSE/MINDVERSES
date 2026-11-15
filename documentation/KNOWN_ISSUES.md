# MINDVERSE — Known Issues Register

**Last Updated:** 2026-11-15  

| ID | Category | Severity | Description | Status | Mitigation / Resolution |
|---|---|---|---|---|---|
| KI-001 | Environment | Low | Subshells spawned in IDE terminal require explicit PATH configuration to access `flutter` (`C:\Users\Corbi\develop\flutter\bin`) and `adb` (`C:\Users\Corbi\AppData\Local\Android\Sdk\platform-tools`). | Monitored | Shell commands explicitly load user PATH or prepend the bin directories. Recommended adding to system PATH permanently. |
| KI-002 | Version Control | Low | Git is installed (`2.56.0.windows.4`), but repository is not yet initialized in `C:\Users\Corbi\StudioProjects\MINDVERSE`. | Open | Initialize git repository and commit baseline in Phase 2. |
| KI-003 | Environment | Trivial | Visual Studio C++ desktop workload not installed. | Ignored | Non-issue; MINDVERSE targets Android and iOS, not Windows native desktop. |
