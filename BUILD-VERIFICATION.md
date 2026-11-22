# HOTD4 Special v1.0.0 verification

## Gameplay and retained Special fixes

Two private instrumented 85000-frame route runs selected opposite paths and exited 0. Route-choice captures showed both original previews; gameplay, cutscenes and player HUD were sampled. These assisted runs do not establish every ending variant or an unassisted full clear. Special's own 16:9, path preview, unwanted wipe suppression, HUD/ammo anchoring and native Start-skip code is retained.

## Justice mouse shaking

The initial native type 6c grab previously ignored genuine shake when the player's first-shot/grenade input latch was zero. The host now opens only that active player's zero latch on valid shake during a gameplay grab. Native SwingProc/InputSwing handles timing, resistance and the success branch without bypasses.

A before trace showed resistance 10 until timeout despite valid packets. After the fix, native resistance decreases 10 -> 6.4 -> 2.8 -> 0 and original success command 084b32c4 executes. Subsequent type 08 Justice grabs also succeeded in a 4300-frame run. Ten automated checkpoint cases passed: absolute 720p and raw-relative 4K shake; stationary input, Reload alone, tiny jitter and steady one-direction sweep; final default-paced horizontal and vertical gestures; and preservation of native nonzero latch state. Negative cases retain resistance 10 and correctly time out. Fixtures use real SDL events and a cloned cabinet save, without writing resistance or forcing success.

## Shared runtime and input

Private native tests injected two-player Raw Input and mixed co-op packets into the actual game. Both magazines depleted independently; off-screen trigger reload refilled the appropriate player, obeyed the option, and preserved explicit reload. Final 6600-frame runs in both input modes exited 0. Physical Sinden/DolphinBar and real Parsec host/guest sessions were not available.

## OpenXR

Private simulated-runtime comparisons verified nonblack live scenes in both eyes without the old duplicate scene rectangle. Forced termination/relaunch through the launcher preserved separate configuration and cabinet state; orderly reset/exit and synthetic X presses passed. This is experimental support: simulated-runtime checks do not replace physical headset, Quest/Virtual Desktop, controller or driver tests. Not every historical VR report is declared resolved.

## Original animated crosshair

Both English WPF menus saved and reopened the new style/size/color settings and rendered an animated preview. Both native desktop executables loaded the locally extracted original Name Entry sprites and rendered them during real game frames (1203 frames, exit 0). Extraction reads the owner's normal HOTD4 playerranking.bnk. No texture or native cache is shipped. Other styles retain their IDs.

## Distribution

The package manifest allows only hand-maintained source, local tools/scripts, documentation and procedural crosshair previews. No ELF, generated guest C, bank, texture, audio, movie, screenshot, cabinet state, prebuilt game executable or local native crosshair cache is permitted. Desktop and VR production sources/executables are scanned for private QA markers before use. Portable release, input, save and gameplay-option tests are run before publishing.


## Final v1.0.0 installation verification

Fresh stripped-function discovery produced 39492 functions; the resulting bounds file and all 99 freshly lifted C units matched the validated local baseline exactly. OpenGL host wrappers were generated locally. Desktop and OpenXR targets compiled with the isolated MSYS2 toolchain; the .NET GUI launcher compiled with native Windows paths. No generated guest unit is distributed.

Setup completed into a separate installation with only the owner's supported Special dump and cached build tools. It copied arcade data locally, resolved runtime DLL dependencies, compiled the console-free GUI launcher and rendered its 1920x1080 menu image locally. The final image was visually inspected at full 16:9. The initial install does not seed cabinet state from the source dump.

The newly installed desktop loaded the original Name Entry cache and completed a 1203-frame native test (exit 0). Its real direct-launch script then completed 4500 game frames with the copied installed dump and original crosshair loaded; the gameplay framebuffer was inspected. The launcher verifies ELF SHA-256 using .NET, including when Get-FileHash is not available through PowerShell module autoloading. The frame-logging path generated its CSV in Frame Logs. An update rerun preserved byte-identical contents for 15 seeded preferences, cache and desktop/VR cabinet-state files and retained the existing menu background.

Portable mouse-shake, mixed co-op, high-score decoder, XR capture, atomic-save and gameplay-option tests passed against this repository's runtime sources. Python publishing/dependency tests and WPF settings tests passed. Incorrect normal-game input was rejected by Special's installer. Production source and desktop/VR/GUI executables were scanned for private instrumentation markers; none were present. The installed OpenXR loader matched the genuine toolchain DLL (SHA-256 0fe0938c0a591c9dbfca835793bae04e54e19fb0f907aea54a81e8445a968df3).

This release-build check does not replace the earlier recorded gameplay regression checks or a physical headset/lightgun/Parsec test. Experimental OpenXR and assisted-playthrough limits above still apply.
