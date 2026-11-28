# HOTD4 Special Local Builder

## Gamepad

In the Windows desktop launcher, choose **Gamepad (P1 + P2)** in **Settings → Graphics / Input** and save. The first controller is assigned to P1 and the second to P2. Either stick aims. **RT / A** shoots, **X / LB** reloads, **LT / B** throws a grenade, **Y / RB** changes fire mode and **Menu / Start** joins. Click the left stick to insert a credit. **View / Back** opens the pause menu, where the D-pad navigates and **A** selects.

Full Windows builder for **The House of the Dead 4 Special**. Download **HOTD4SP-Local-Builder-v1.1.5.zip** from the [v1.1.5 release](https://github.com/davidptrssvea/HOTD-4-Special-recomp/releases/tag/v1.1.5), extract it, run **Setup.cmd**, and select your own extracted Special arcade dump. The installer builds the game locally from a compatible dump.

Open **HOTD4SP-PC/Play HOTD4 Special.cmd**, or **HOTD4SP-PC/HOTD4SP_Recomp/Play HOTD4 Special.exe** for the console-free English launcher. The optional OpenXR launcher is inside HOTD4SP_Recomp. This is the separate Special game, not an add-on to the [normal HOTD4 builder](https://github.com/davidptrssvea/HOTD4-recomp).


## Keyboard aiming (v1.1.5)

Choose **Settings > Graphics / Input > Input Mode > Keyboard (P1 + P2)**, save, and restart the game. Open **Settings > Key Bindings** to change either player's movement and action keys. The in-game pause menu also provides Key Bindings (PgUp/PgDn switches pages).

| Action | Player 1 | Player 2 |
| --- | --- | --- |
| Aim | Arrow keys | WASD |
| Shoot | Right Ctrl | Space |
| Reload / shake | Right Shift | Q |
| Grenade | Right Alt | E |
| Fire mode | End | Tab |
| Coin / Start | 5 / 1 | 6 / 2 |

Keyboard mode keeps the two seats independent. Use P2's Coin and Start to play solo from P2, or join both players for co-op. Movement is frame-rate independent and stops when the game loses focus or opens the pause menu. The keyboard-specific Service key defaults to F10 so S remains available for P2 aiming. Mouse and lightgun modes retain their existing controls and profiles.

## Display options (v1.1.4)

In **Settings > Graphics / Input**, choose **V-Sync > On** to synchronize desktop presentation with the display. Save and restart the game to apply. Off remains the default. The desktop setting does not alter OpenXR headset timing.

On the main **Settings** page, choose **Aspect Ratio > 4:3** (below Display Mode, next to HUD) for a 4:3 game canvas, including 640 x 480 and 800 x 600 outputs. Wider displays show side bars. The game, HUD and pointer use the same fitted picture area. 16:9 remains the default. Save, exit the game and relaunch to apply an aspect-ratio change. This is a desktop option; OpenXR keeps its headset view.

## Shader compatibility in current source

The matrix-index correction confirmed with HOTD4SP-Matrix-Index-Shader-Test is integrated into the regular OpenGL runtime, including builds made by Setup. It keeps character animation indices compatible with the game's legacy vertex input and preserves the earlier white-screen shader fixes. No separate test executable is needed in future releases built from this source.

The currently published v1.1.11 installer predates this correction. Do not replace a working test executable with an older build expecting the correction to be retained.

## Supported dump

Select a folder containing `elf/hod4M.elf` and a populated `fs` folder. You can also select its `elf` folder, a parent containing `hotd4sp`, or a parent containing `disk0`. The installer verifies the Special ELF SHA-256:

`b84c70d9940d5f5fa7d287fd8c6b050444fdcbc2fd742d3afc74a1099bbec5fe`

Normal HOTD4 ELF files are not interchangeable with Special. The source dump is left in place; its assets are copied into your chosen installation on your PC. No cabinet save is seeded from the source dump.

## Included

- Solo gun-seat selection: **G (P1)** or **Kate (P2)** under **Settings > Gameplay > Solo Player**. Your primary mouse/lightgun, crosshair, shooting, reload/shake and grenade controls follow the chosen seat.
- English launcher and settings, arcade/practice chapters and frame-time CSV logging.
- Optional **Home** rules with individual lives, manual reload and blended camera turns.
- **4:3 Expanded** and **5:3 Expanded** framing for live 3D at 16:9, HUD/ammo anchoring, restored path previews and fixes for unwanted wipe rectangles. Special's own cutscene/ending and Start-skip logic is retained.
- Mouse shaking to escape grabs, including Justice's first grab before firing a shot. Native resistance, timing and success/failure behavior are preserved.
- Resolution selection including custom sizes, windowed/borderless output, MSAA, AF, HUD scale, configurable crosshairs and Sinden border thickness.
- Raw relative mouse speed/smoothing, individual Raw Input lightgun selection, mixed co-op (host lightgun P1 plus injected/Parsec mouse P2), key bindings and visible control summary.
- Independent off-screen trigger reload for lightguns and optional enhanced blood using original local effects. Arcade rules retain Special's original on-screen trigger-release reload.
- Updated optional OpenXR build, per-session logs and separate VR configuration/cabinet state. Shared stereo, reset, capture and interruption-safety fixes are included.
- **Name Entry (Original)** animated crosshair with size/color controls and preview. Special does not include this normal-game resource: select your own **normal HOTD4 dump** when prompted. The original sprites and timelines are extracted locally; other crosshair styles need only the Special dump.

On slower PCs, open **Settings > Apply 720p Performance** to save a 1280x720 internal render resolution and turn off MSAA and anisotropic filtering. Borderless still fills the display. For a lower GPU load, select 960x540 under **Render Resolution** and save. Adjust MSAA and anisotropic filtering under **Graphics / Input**.

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

## Game Library

Open **Game Library** in the main menu to choose between installed copies of HOTD4, HOTD4 Special, HOTD EX and Scarlet Dawn. **Play** starts the game using its saved settings. **Settings** opens that game's own settings, and **Menu** opens its regular launcher for features such as chapter selection. Older installations may offer **Menu** only. Setup registers each installation for your Windows account. The library also checks nearby folders and remembered Setup locations. Use **Locate installed game...** if an existing installation is missing.


## Solo player choice

In **Settings > Gameplay > Solo Player**, choose **G (P1)** (default) or **Kate (P2)** and **Save**, then start Arcade normally. The same selector is available under **Pause > Settings > Gameplay**; restart Arcade/Chapter to apply a change made during play. It supports absolute mouse, Raw Relative mouse and Raw Input lightguns. Your primary gun device remains the same physical device.

Special uses **G** and **Kate**. The solo selector chooses which seat receives the primary input. Default **5/C** adds shared credits and **1/Enter** starts the ride or skips supported cutscenes. The other seat can shoot when a second gun is enabled. Mixed co-op and Parsec modes use their normal assignments. Experimental OpenXR uses its existing controller mapping.

## Desktop rules and gameplay framing

- Under **Settings → Gameplay → Rules**, choose **Home** for three lives per participating player, manual reload and a short blend when the arcade ride switches camera views. The original arcade sends damage to the cabinet, so Home assigns each hit to one eligible player and alternates in co-op. A player who runs out of lives stops shooting while their partner can finish the run. Off-screen lightgun reload follows its own setting. **Arcade** is the default.
- Under **Settings → Graphics / Input → 16:9 Gameplay Framing**, **4:3 Expanded** (default) retains the full 4:3 vertical field of view. **5:3 Expanded** retains the tighter height of the arcade's 1280×768 mode. Both extend the live 3D view horizontally to 16:9. Full-screen movies and the HUD retain their original framing.

Save the selection in the launcher and start Arcade or Chapter Practice. These settings apply to the Windows desktop build.

## Menu updates

The main menu checks GitHub for the latest stable release in the background. Open **Updates** to read the release notes and choose whether to download and install a newer version. Setup verifies the package and builds the update locally from the arcade dump in your installation. The menu reopens after installation.

The update replaces the launcher and runtime files. It keeps settings, cabinet saves, the existing game dump and installed OpenXR support. The update folder beside the installation holds the Setup log and the previous versions of replaced files. Internet access and free disk space for a local build are required.

To add the updater to an installation from an earlier release, run this builder's Setup and select the existing installation folder. Update `ui/hotd-update-version.txt` to match the tag when preparing a release.

## Remembered Setup folders

Manual Setup remembers your last successfully used **arcade dump** and **installation** folders, separately for HOTD4, Special and EX. Both paths are shown in the opening dialog; edit them or use **Browse** beside either field. Cancelled/failed builds and validation-only runs do not replace the last successful choices. Explicit command-line paths still take precedence, and the launcher updater remains automatic and does not change this history.

Folder history is stored locally in `%LOCALAPPDATA%\HOTD-Setup\Normal.json`, `Special.json` or `EX.json`. It contains paths only. A deleted/moved dump can be replaced using Browse; a corrupt history file falls back to the usual defaults. Settings and cabinet saves remain in your installed game folder.

Press **Start** (default **1 / Enter**) to skip **Gameplay Advice**. A single press is retained if native loading is still busy; the game performs its original script/resource cleanup. Existing story, boss and ending skips are retained.
