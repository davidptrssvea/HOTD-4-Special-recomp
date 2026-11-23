# HOTD4 Special Local Builder

Full Windows builder for **The House of the Dead 4 Special**. Download **HOTD4SP-Local-Builder-v1.0.2.zip** from the [v1.0.2 release](https://github.com/davidptrssvea/HOTD-4-Special-recomp/releases/tag/v1.0.2), extract it, run **Setup.cmd**, and select your own extracted Special arcade dump. The installer builds the game locally; a compatible dump is required.

Open **HOTD4SP-PC/Play HOTD4 Special.cmd**, or **HOTD4SP-PC/HOTD4SP_Recomp/Play HOTD4 Special.exe** for the console-free English launcher. The optional OpenXR launcher is inside HOTD4SP_Recomp. This is the separate Special game, not an add-on to the [normal HOTD4 builder](https://github.com/davidptrssvea/HOTD4-recomp).

## Supported dump

Select a folder containing `elf/hod4M.elf` and a populated `fs` folder. You can also select its `elf` folder, a parent containing `hotd4sp`, or a parent containing `disk0`. The installer verifies the Special ELF SHA-256:

`b84c70d9940d5f5fa7d287fd8c6b050444fdcbc2fd742d3afc74a1099bbec5fe`

Normal HOTD4 ELF files are not interchangeable with Special. The source dump is left in place; its assets are copied into your chosen installation on your PC. No cabinet save is seeded from the source dump.

## Included

- Solo gun-seat selection: **G (P1)** or **Kate (P2)** under **Settings > Gameplay > Solo Player**. Your primary mouse/lightgun, crosshair, shooting, reload/shake and grenade controls follow the chosen seat.
- English launcher and settings, arcade/practice chapters and frame-time CSV logging.
- 16:9 scene presentation, HUD/ammo anchoring, restored path previews and fixes for unwanted wipe rectangles. Special's own cutscene/ending and Start-skip logic is retained.
- Mouse shaking to escape grabs, including Justice's first grab before firing a shot. Native resistance, timing and success/failure behavior are preserved.
- Resolution selection including custom sizes, windowed/borderless output, MSAA, AF, HUD scale, configurable crosshairs and Sinden border thickness.
- Raw relative mouse speed/smoothing, individual Raw Input lightgun selection, mixed co-op (host lightgun P1 plus injected/Parsec mouse P2), key bindings and visible control summary.
- Independent off-screen trigger reload for lightguns and optional enhanced blood using original local effects. Special's original on-screen trigger-release reload remains.
- Updated optional OpenXR build, per-session logs and separate VR configuration/cabinet state. Shared stereo, reset, capture and interruption-safety fixes are included.
- **Name Entry (Original)** animated crosshair with size/color controls and preview. Special does not include this normal-game resource: select your own **normal HOTD4 dump** when prompted. The original sprites and timelines are extracted locally; other crosshair styles need only the Special dump.

Pause with **Esc**, add a coin with **5/C**, start with **1/Enter**, shoot with left mouse, reload with right mouse, and throw a grenade with **Space**. Check Settings and the launcher summary for current bindings. Use **Start** for supported cutscene skips.

Special's launcher currently does not expose Trophies, Photo Mode or Model Viewer. VR remains experimental: automated simulated-runtime tests passed, but physical headset/runtime testing is still needed. See BUILD-VERIFICATION.md for exact coverage and limits.

## Installation and updates

Windows 10/11 x64, Windows PowerShell 5.1 and .NET Framework 4.x are required. Allow approximately **10 GB free space beyond your original dump** for tools, generated code, build intermediates and an installed copy. Initial setup needs internet for signed MSYS2 dependencies and a hash-verified Python ELF reader. No separate Python, compiler or xz utility is needed. The first Special build can take substantially longer than normal HOTD4 because its stripped executable needs function discovery before lifting; progress is printed during that phase. The default tool cache is `%LOCALAPPDATA%/HOTD4-Builder/msys64`, shared with normal HOTD4.

Gameplay requires an OpenGL compatibility driver; the optional menu image also uses it. OpenXR additionally requires a compatible headset/runtime and an OpenGL 4.3 compatibility context. No minimum playable CPU/GPU has been benchmarked for Special.

Run `Setup.cmd -InstallDir "D:\Games\HOTD4SP-PC"` to choose an installation path. Use `-OpenXR` to build desktop and VR without the interactive VR prompt. Advanced options: `-DumpPath`, `-ToolchainPath`, `-Jobs`, `-NoDownload` (cached tools only), and `-ValidateOnly` (verify package/dump without installing).

For future updates, extract the new builder and select the same Special dump and existing installation path. Settings in HOTD4SP_Recomp and existing cabinet saves are preserved. You may delete the downloaded ZIP, extracted builder and tool cache after installation; keep the original dump and installed HOTD4SP-PC folder. With the default location, the installed folder is inside the extracted builder: keep that subfolder. Clearing the cache means tools must be downloaded again next time.

## Asset-free distribution and credits

The package contains hand-maintained host/runtime source, local generation/build scripts and procedural crosshair previews. It contains **no arcade ELF, game banks, textures, movie, audio, menu screenshot, prebuilt game executable, lifted game code, native crosshair cache, saved progress or cabinet NVRAM**. All lifting and asset processing happens on the user's own computer. Local game-derived files must never be committed or redistributed with the builder.

Based on lindbergh-recomp-ports, lindberghrecomp and pcrecomp by sp00nz and contributors (including the lialan ports). Their MIT license notices are retained in source and copied to the installation; dependency license notices are copied from the toolchain. This project is unofficial and is not affiliated with Sega.

## Setup diagnostics and recovery

Setup verifies download size and SHA-256, retries interrupted or mismatched downloads, and tries the official GitHub mirror for the same pinned MSYS2 archive. Existing compiler executables, headers and Python imports are checked before a cached toolchain is reused. No checksum check is bypassed.

The default compiler worker count adapts to available RAM and CPU cores; use `-Jobs 1` to reduce memory pressure further. Long-running commands print a periodic working message. Setup checks writable/protected paths and reports available disk space before downloading; keep the free-space allowance listed in the system requirements. Concurrent installers using the same builder, destination or tool cache are blocked.

Each run writes a diagnostic log under `%LOCALAPPDATA%\HOTD4-Builder\Logs`. If Setup fails, send the latest log with the error report (review local paths/usernames before sharing). Rerun Setup to reuse verified downloads and repair missing tool packages. If the tool cache remains broken, run `Setup.cmd -RepairTools`: it preserves the previous recognizable MSYS2 folder under a `.backup-...` name and installs a fresh isolated cache. This needs internet access. Your original dump, installed settings and saves are retained.

## Switch between HOTD4 and HOTD4 Special

Both start menus include **HOTD4** and **HOTD4 SPECIAL** buttons. Select the other installed game to open its menu, with its own chapters, settings and saved progress. The current menu closes during the handoff. Setup registers each installation in your Windows user profile; nearby installations are also detected automatically. If the games are elsewhere, choose **Locate other game...** once and select the other installed game folder. A missing game stays disabled until located. Install each game separately using its own supported arcade dump; linking the menus does not copy any game assets between installations.

## Solo player choice

In **Settings > Gameplay > Solo Player**, choose **G (P1)** (default) or **Kate (P2)** and **Save**, then start Arcade normally. The same selector is available under **Pause > Settings > Gameplay**; restart Arcade/Chapter to apply a change made during play. It supports absolute mouse, Raw Relative mouse and Raw Input lightguns. Your primary gun device remains the same physical device.

Special uses **G** and **Kate**. The solo selector chooses which seat receives the primary input. Default **5/C** adds shared credits and **1/Enter** starts the ride or skips supported cutscenes. The other seat can shoot when a second gun is enabled. Mixed co-op and Parsec modes use their normal assignments. Experimental OpenXR uses its existing controller mapping.

## Desktop rules and gameplay framing

- Under **Settings → Gameplay → Rules**, choose **Home** for three lives per participating player, manual reload and a short blend when the arcade ride switches camera views. The original arcade sends damage to the cabinet, so Home assigns each hit to one eligible player and alternates in co-op. A player who runs out of lives stops shooting while their partner can finish the run. Off-screen lightgun reload follows its own setting. **Arcade** is the default.
- Under **Settings → Graphics / Input → 16:9 Gameplay Framing**, **4:3 Expanded** (default) retains the full 4:3 vertical field of view. **5:3 Expanded** retains the tighter height of the arcade's 1280×768 mode. Both extend the live 3D view horizontally to 16:9. Full-screen movies and the HUD retain their original framing.

Save the selection in the launcher and start Arcade or Chapter Practice. These settings apply to the Windows desktop build.
