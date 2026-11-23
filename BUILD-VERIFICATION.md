# HOTD4 Special Windows builder verification

## v1.1.4: desktop display options

Aspect Ratio is on the main Settings page next to HUD and saved by Settings > Save. WPF tests verify visibility, page placement, Save/Back behavior, reopening 4:3/16:9, Special framing state and reachable bottom buttons.

Complete launcher tests initialize the updater and game switcher and accept `-InstalledApp` to check deployed files. A missing updater is explicitly rejected. All three complete installed-menu tests pass; the normal game's actual `Spela HOTD4 i 4K.cmd 0` entry completed 90 native frames with an isolated cabinet save, exit 0.

- Native Windows desktop build completed with the existing locally generated game code.
- Real WPF menu checks passed: default V-Sync Off, save On, reopen On, save Off; bottom actions remain reachable. Run `powershell.exe -NoProfile -ExecutionPolicy Bypass -File .release/test_display_controls.ps1`.
- Real SDL/OpenGL runs accepted swap interval 0 and 1; the active interval was read back from the NVIDIA driver. This does not verify every GPU driver or OpenXR headset.
- Real gameplay captures checked at 640 x 480 and 1280 x 960 with 4:3 selected, plus 4:3 presentation inside a 1280 x 720 output. The normal game's final presented framebuffer was checked for black side bars. Existing 16:9 gameplay was also checked after the normal game's viewport fix.
- Native coordinate checks covered 50 SDL/raw-gun grid points, including the edges and off-screen bars; menu tests covered aspect persistence and fitting/clamping of requested render sizes. No physical CRT or lightgun was attached for this verification.


### Release builder validation

The complete Windows builder ran with a verified local dump and a separate staged installation. It compiled the production desktop and OpenXR targets and copied all launcher code, updater dependencies and the release version stamp into the stage. Generated game code/object caches were reused or refreshed as required; this was not a new empty-toolchain installation. The updater stage copied no original game data. Complete menu tests and active desktop V-Sync readback passed. Extracted source-only packages passed Windows PowerShell 5.1 Setup integrity and supported-dump validation.


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

## Local follow-up: builder reliability (2026-11-22)

Added strict size/SHA-256 download retries and an official mirror for the same pinned MSYS2 archive; verified-cache reuse remains offline-capable. Real Windows PowerShell 5.1 HTTP tests served a truncated primary response followed by the valid mirror payload. Negative tests rejected repeated wrong hashes and preserved the previous cache. The same tests cover exclusive locks, native stderr with exit 0, nonzero exit/error tails, missing commands, writable paths with spaces/non-ASCII characters, protected source/dump paths and missing tool detection. Python dependency tests cover connection reset, corrupt payload and eventual verified recovery.

Full cached desktop update runs passed for normal HOTD4 and Special, including compilation, installation, launcher compilation and retained local menu image. Five normal and six Special existing configuration/save files retained their hashes. Inherited invalid PYTHONHOME/PYTHONPATH/CC/CFLAGS were cleared by Setup. Previously validated generated game units were reused because the changes affect orchestration, not lifting/GL generation. This is an update-path test; a fresh tool download/clean regeneration was not repeated. Generation heartbeat output was observed during a deliberately stopped isolated Special bounds scan; its interrupted setup returned failure with phase and full log path before a subsequent cached update passed.

Tests used Windows 11 x64 with Windows PowerShell 5.1; this is not a new Windows 10 LTSC VM test. No physical headset/lightgun/Parsec tests were added in this change. These local changes have not been published as a GitHub release.

## Local follow-up: shared game selector (2026-11-22)

Both main menus now show HOTD4 and HOTD4 SPECIAL choices. The other installation is discovered from a per-user registry or nearby default folders, or selected once with Locate other game. Setup registers the installed path after launcher compilation; registration failure is optional and does not fail an otherwise completed installation. A handoff starts the other GUI launcher, clears inherited game-specific environment/dump/save overrides, removes the previous game DLL directory from PATH, and closes the old menu. The installations retain their own settings, chapters, saves and resources.

Windows PowerShell 5.1 tests passed for normal/Special layouts, sibling and saved discovery, stale/missing/corrupt paths, spaces/accents/metacharacters, replacement registration, clean child environments and nested scriptblock closure visibility. Real WPF click handlers were rendered and verified in both menus at 1280x720, including settings-page visibility and old-window closure. Actual GUI-to-GUI handoffs were tested in both directions with isolated user profiles; each target native game rendered 450 frames at 1280x720, exited normally, and returned to its own menu. Private UI automation/diagnostics were removed from the validation installs afterwards. These were assisted launch tests, not new playthroughs.

Both cached Setup runs passed automatic library registration and preserved their existing settings/cabinet files. Local user deployments changed only the two menu/library scripts in each installation; hashes of 17 normal and 15 Special settings/save/config files stayed unchanged. No game assets are added to the builder manifests. This change has not been published as a GitHub release.

## Release v1.0.1 verification

This release includes the shared game selector and installer recovery changes documented above. Earlier local follow-up notes record pre-publication tests. The release workflow now gates publication on Windows PowerShell 5.1 installer/library tests on windows-latest, plus Python dependency/build/publisher tests and portable runtime checks on Linux. Packages are generated only from the SHA-256 manifest and reject generated game code, executables and arcade asset formats.

## v1.0.2 — G/P1 or Kate/P2 primary controls

- Native assisted desktop runs: 5,053 frames each for default G with absolute mouse and Kate with absolute mouse, Raw Relative mouse, and synthesized Raw Input absolute-lightgun packets. Shared ride Start/coins boot correctly, the selected seat fires 30 rounds, reload restores its magazine and grenade count changes 3 -> 2. The other seat does not consume ammunition. Native P2 HUD/crosshair was visually checked. Special creates both native player objects; the test does not assume the normal game's independent join/state rules.
- Justice checkpoint tests, using actual SDL mouse motion and the native SwingProc/InputSwing: G/absolute succeeds in 33 frames, Kate/absolute in 36 and Kate/Raw Relative in 27. Kate with Reload alone receives no resistance decrease and takes the original 276-frame timeout. Private checkpoint fixtures do not force the success outcome or alter native resistance/timing. They are not shipped.
- Real WPF event-handler tests save/reopen the selector, check Kate's primary-device label, preserve shared Coin/Start labels, and disable/retain the preference in both dedicated mixed co-op modes. The rendered settings page was inspected.
- Production desktop and optional OpenXR compiled. Cached Setup with desktop/OpenXR preserves 16 preference/cache/cabinet files, including solo-player.txt. The final source/executables contain no private QA hooks. Portable button tests additionally cover Special's shared Start behavior, plus existing off-screen reload, co-op isolation, interruption-safe saves and OpenXR capture regressions. Windows PowerShell 5.1 setup/library checks and Python release tests pass.

These are automated native integration/checkpoint tests using the owner's dump and cloned saves, not a new full human playthrough. No physical lightgun, Parsec session or headset was available for this update. OpenXR controller assignments are unchanged and remain experimental. Source-only ZIP integrity and extracted Setup validation are checked before publication; GitHub release CI gates publication and the published ZIP is downloaded and compared to its manifest/source.

## Desktop Home rules and 16:9 gameplay framing

- Solo G and solo Kate each went from three lives to zero under native damage and reached the arcade Game Over state. Simulated two-player input verified independent life loss, P2 firing after P1 was out, and Game Over after the final life.
- A scripted trigger burst and release restored the arcade magazine from 14 to 30 rounds. Home held at 14 until Reload and then refilled to 30. Home's off-screen reload was checked with the option enabled for G and disabled for Kate.
- The original 5:3 cabinet projection had the same horizontal scale as 4:3 and a vertical scale 1.25 times higher. The 16:9 presets were rendered against those references. The same off-center screen input produced camera-ray slopes 0.8 times as large on each axis in 5:3 Expanded, matching the projection change.
- A Chapter 2 desktop session with 4x MSAA completed 11,500 frames and recorded four ride-camera blends. The installed executable captured 49 frames around a subsequent turn, showing the outgoing view, a blend, and the incoming view. Arcade uses the existing transition handling.
- Both settings were saved and reopened using the WPF click handlers. Windows Setup built and installed the desktop and OpenXR executables and generated the local menu image. A 4K desktop run from the installed launcher completed 600 frames.

The checks used the supported local dump, scripted input and isolated saves. Physical lightgun and headset testing were outside this run.

## v1.1.1 desktop performance

- A hidden 3,650-frame Chapter 1 comparison at 1920 x 1080, with MSAA off and 16x anisotropic filtering, measured 33.25 seconds of process CPU time in v1.1.0 and 30.94 seconds in v1.1.1. Average present intervals from frame 2,200 through 3,649 were 16.82 ms and 16.97 ms, respectively. The test used Windows, a Core i5-13400F and an RTX 4070 Ti. Performance on older hardware remains to be measured.
- A hidden Chapter 2 run with Home rules, 5:3 Expanded framing, 720p and MSAA off completed 4,070 frames and confirmed a ride-camera crossfade. The test used scripted input and an isolated cabinet save.
- The Windows PowerShell 5.1 menu test applied the preset, reopened the saved settings and returned the selected chapter to the launcher. Home rules and 5:3 Expanded were selected throughout. The desktop executable was rebuilt, and the updated stereo source compiled with the existing Windows OpenXR configuration.

## v1.1.3: remembered manual Setup folders

Windows PowerShell 5.1 checks cover separate Normal/Special/EX histories, spaces and Unicode in paths, atomic replacement, corrupt/wrong-edition/relative history fallback, saved prefill, explicit installation overrides, cancellation and preserving the last successful choices. Real WinForms control tests cover both Browse handlers, editing, input validation, Continue and control bounds. Only the OS folder picker is substituted for unattended tests. The same tests run in GitHub's Windows release checks.

Real EX Setup was also run with the shared helper: a staged build created no history; a successful ordinary installation recorded the verified dump/install paths; a failed installation, ValidateOnly and a subsequent StageUpdate left that history byte-identical. Existing INI, cabinet save, local background and profile data remained byte-identical. Normal/Special package and supported-dump validation and existing Windows installer recovery checks passed. This tests the shared helper's real Setup integration without claiming a fresh native recompilation of unchanged Normal game code.

All release packages retain the existing verified launcher updater. Only paths are remembered; no game assets are included.

## Gameplay Advice Start skip

Built both desktop and OpenXR targets from the updated production Special source. The new input scope is bounded to the original instruction script before the opening; it queues a single Start edge while native loading is busy and uses EventSkip's original resource/timer handling. Previous story/boss/ending handling remains in place.

Five real native runs completed 3,500 frames each: a no-skip baseline, an early single 1 press during the safety/advice prelude, Enter on the first Gameplay Advice panel, 1 on the grenade-advice panel, and 1 near the end of the instruction sequence. A private observation-only build logged the native commands; it contains the production logic plus diagnostic logging, not scripted state changes. The baseline waited through the instructions. All four single-press cases exited the instruction script and continued through the opening into gameplay, exit 0. Captures confirmed the original advice screens and subsequent rendered street/enemies. The early request was retained across two native skip steps. Private probes/captures/ELFs are excluded from the release.

This is not a fresh full playthrough of every route/boss/ending, nor a physical headset test. OpenXR compilation passed; headset behavior still needs hardware testing.

Browse callbacks are tested in both direct -File and dot-sourced Windows PowerShell invocation; the picker delegate is captured explicitly so it remains available across UI event scopes.
