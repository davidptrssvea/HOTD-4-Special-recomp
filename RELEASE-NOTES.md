# HOTD4 Special Local Builder v1.0.0

First full Windows release in the dedicated Special repository, with an optional OpenXR build.

Includes Special's 16:9, HUD/ammunition placement, path-preview, unwanted wipe-rectangle and Start cutscene-skip fixes; the English launcher/settings; mouse-shake escapes including Justice's first grab; independent off-screen lightgun reload; mixed lightgun/mouse co-op; optional enhanced blood; updated shared VR rendering/reset/logging code; and the new **Name Entry (Original)** animated crosshair.

**Download HOTD4SP-Local-Builder-v1.0.0.zip**, extract it and run **Setup.cmd** with your own supported extracted **HOTD4 Special** arcade dump. The ELF must have SHA-256 `b84c70d9940d5f5fa7d287fd8c6b050444fdcbc2fd742d3afc74a1099bbec5fe`. Choose Yes for optional OpenXR. The new original crosshair additionally reads the Name Entry resources from your own **normal HOTD4 dump**, selected in Settings; Special's dump does not contain that resource.

For updates use the same dump and your existing installation path: `Setup.cmd -InstallDir "D:\Games\HOTD4SP-PC"`. Existing installed preferences and cabinet saves are preserved. Launch **HOTD4SP-PC/Play HOTD4 Special.cmd**.

Requires Windows 10/11 x64, PowerShell 5.1/.NET Framework 4.x, internet for first-time build tools and approximately 10 GB free beyond the original dump. Gameplay needs an OpenGL compatibility driver. OpenXR requires a compatible headset/runtime and remains experimental; physical headset testing is still needed. See README and BUILD-VERIFICATION for supported layout, coverage and limits.

No game assets, ELF, lifted code, prebuilt game executable or cabinet save are included. Everything is generated locally from the user's own dump.
