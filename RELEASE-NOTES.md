# HOTD4 Special v1.1.5 — independent keyboard aiming

Full Windows local builder. **No game assets, arcade executables or generated game code are included.** Setup builds locally from your own supported extracted arcade dump.

## New in this release

- **Keyboard aiming for both players:** select **Settings > Graphics / Input > Input Mode > Keyboard (P1 + P2)**, save and restart the game.
- P1 uses **arrow keys**, P2 uses **WASD**. Movement and shooting controls are independent for each player.
- Remap both players' movement, shooting, reload/shake, grenade and fire-mode keys in **Settings > Key Bindings**, including the in-game pause menu. The launcher shows the active keyboard controls.
- Frame-rate-independent movement, normalized aim positions and release of held controls when pausing or losing focus. Repeated internal window-open calls preserve aim positions.
- Existing mouse/lightgun bindings load with the new keyboard defaults. S remains P2's Down key in keyboard mode; its separate Service binding defaults to F10.

| Action | Player 1 | Player 2 |
| --- | --- | --- |
| Aim | Arrow keys | WASD |
| Shoot | Right Ctrl | Space |
| Reload / shake | Right Shift | Q |
| Grenade | Right Alt | E |
| Fire mode | End | Tab |
| Coin / Start | 5 / 1 | 6 / 2 |

Keyboard mode uses fixed P1/P2 seats. Join either player with their own Coin / Start keys, or join both for co-op.

All previous features are retained, including the launcher updater, remembered Setup paths, V-Sync and selectable 16:9 / 4:3. Existing settings, bindings and saves are preserved when updating. OpenXR remains available; this release adds desktop keyboard controls and does not change headset input.

## Updating

Open **Updates** in the launcher and choose **Download and install**. The updater rebuilds locally using your installed dump and reopens the menu afterward.

Alternatively, extract the full builder ZIP, run **Setup.cmd**, select the same supported arcade dump and choose your existing installation folder. Setup remembers your last successful folders and still offers Browse. Your settings and saves are kept.

## Verification

Both games completed 2,400-frame automated runs with isolated cabinet saves: both players joined, aimed independently, fired and reloaded. Native SDL checks covered remapping, saved profiles, focus/pause release, repeated window-open calls and existing mouse input. Actual WPF menu tests covered all 33 controls, Save/reopen, legacy profiles, mode-specific help and the visible control summary. Movement checks covered 10/60/144 Hz and multiple resolutions. Desktop and optional OpenXR targets build successfully. These tests do not measure physical keyboard rollover and are not full game playthroughs.
