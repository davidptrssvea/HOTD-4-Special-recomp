# HOTD4 Special Local Builder v1.0.1

Full Windows release with all Special v1.0.0 fixes and optional OpenXR.

- **Shared game selector:** HOTD4 and HOTD4 SPECIAL buttons in both menus. Setup records the installed game in your Windows user profile; nearby installations are found automatically. Use **Locate other game...** when they are elsewhere. Switching opens the other game's own menu and closes the previous one, with independent settings, chapters, dump paths and saves.
- **More reliable Setup:** verified download retries and an official mirror for the same pinned MSYS2 archive; real checks/repair for cached compiler/header/Python dependencies; RAM/CPU-based compiler worker limits; regular progress messages and full phase/error logs; writable/protected-path checks; a 64-bit PowerShell start file; and locks against overlapping installers.
- **Tool recovery:** rerun Setup to repair missing packages. `Setup.cmd -RepairTools` preserves the previous recognizable MSYS2 cache and creates a fresh isolated cache. Diagnostic logs: `%LOCALAPPDATA%HOTD4-BuilderLogs`. Checksums remain mandatory.

Retains Special's 16:9/HUD/ammunition fixes, path previews, unwanted-rectangle fixes, supported Start cutscene skips, Justice/mouse-shake escape fixes, configurable controls/crosshairs, Sinden border, off-screen lightgun reload, mixed co-op, optional enhanced blood, frame logging and experimental OpenXR. The new six-chapter P1/P2 run-total overlay is a feature of normal HOTD4; Special keeps its own HUD.

Download **HOTD4SP-Local-Builder-v1.0.1.zip**, extract it and run **Setup.cmd** with your own supported Special arcade dump. To update, select the same dump and existing installation path: `Setup.cmd -InstallDir "D:GamesHOTD4SP-PC"`. Existing preferences and cabinet saves are preserved. Open **HOTD4SP-PC/Play HOTD4 Special.cmd**, or the GUI executable inside HOTD4SP_Recomp.

[Download normal HOTD4 v1.3.11 separately](https://github.com/davidptrssvea/HOTD4-recomp/releases/tag/v1.3.11). The games are separate installations and each requires its own supported dump. **Name Entry (Original)** in Special additionally reads the original crosshair resources from your own normal HOTD4 dump. Trophies, Photo Mode and Model Viewer are currently normal-HOTD4 features.

Tested both menu handoff directions through the real GUI launchers and native games, plus cached updates preserving installed settings/cabinet files and Windows PowerShell 5.1 recovery/checksum/path/lock tests. Full Special lifting was not repeated for this orchestration-only update. OpenXR remains experimental; physical headset/runtime testing is still needed. See BUILD-VERIFICATION.md for exact coverage and README for supported ELF SHA-256 and system requirements.

No arcade ELF, game banks, textures, movies, audio, lifted game code, prebuilt game executable or cabinet save is included. Everything game-derived is generated locally from the user's own dump.
