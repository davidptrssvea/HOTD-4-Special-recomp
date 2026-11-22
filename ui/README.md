# HOTD4 Special Windows launcher

Run **Play HOTD4 Special.exe** to open the English start menu without a console window. The older desktop BAT file opens the same launcher. **Settings.bat** opens the settings page directly.

The launcher expects `hotd4sp-desktop.exe` and its runtime DLLs in the same folder, and the user's own supported dump in the sibling `hotd4sp` folder (`elf/hod4M.elf` and `fs`). It verifies the ELF SHA-256 and does not modify it. No arcade graphics, sound, movies or executable are included in this folder.

- Play Arcade, practice Chapter 1 or Chapter 2, or play with CSV frame logging.
- Render resolution (presets or a custom value) and windowed/borderless output. Rendering remains on a 16:9 canvas; other window proportions use bars.
- MSAA Off/2x/4x/8x, anisotropic filtering, audio volume, and player HUD scale.
- Absolute mouse, raw relative mouse with speed and smoothing, per-device Raw Input lightguns, and mixed co-op (host Sinden/DolphinBar as P1, Parsec mouse as P2).
- Crosshair visibility, model, size, color and live preview; Sinden border and thickness.
- Editable key bindings and a current control summary on the main menu.

**Esc** opens Pause: Resume, Restart Chapter/Arcade, Settings, or Main Menu. **F6** restarts (or use the key you bind). **Start** skips supported cutscenes. Shake the mouse left/right or up/down to escape grabs in mouse modes; Reload continues to reload. Dedicated lightgun mode retains its native button behavior.

Preferences stay beside the installed executable. Practice uses a temporary NVRAM copy so it does not replace arcade progress. CSV logs are written to `Frame Logs`; startup diagnostics are in `hotd4sp-last-run.log`.

A locally generated `hotd4sp-menu.jpg` can supply the backdrop. Keep any image derived from the arcade dump in the user's installation, outside distributable source/packages.

Trophies, Photo Mode and Model Viewer are not exposed by this Special launcher.

Choose **Settings > Crosshair Style > Name Entry (Original)** for the original red P1 / blue P2 sprites, idle pulse and shot animation. Size, color and animated preview remain available. Special does not contain these normal HOTD4 Name Entry resources: select your own normal HOTD4 dump when prompted. The launcher creates `native-crosshair.bin` locally; this cache and the selected source path must never be included in distributable packages.

**Settings > Gameplay** controls off-screen trigger reload (lightguns) and optional enhanced blood. Off-screen reload remains independent for both players. Special's on-screen trigger-release reload behavior is preserved.

**Play HOTD4 Special (VR OpenXR).cmd** starts the updated OpenXR build without a persistent console. Its `vr.cfg` and `lindbergh_nvram.vr.bin` live beside the launcher; VR logs are in `VR Logs`. Reset exits the old process before starting a new session. An actual headset/runtime test is still required after local mock-runtime verification.

`Launcher.cs` builds as a .NET Framework GUI executable using Windows PowerShell 5.1's System.Management.Automation assembly and System.Windows.Forms. It hosts the WPF menu in an STA runspace; it does not change the machine's PowerShell execution policy.
