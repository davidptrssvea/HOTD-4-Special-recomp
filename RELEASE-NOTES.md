# HOTD4 Special v1.1.11 – Gamepad support

- Added two-player gamepad support to Windows desktop play, including stick aiming, shooting, reload, grenades, and pause-menu navigation.
- The system mouse pointer is hidden during gamepad play.
- Added a targeted OpenGL retry for NVIDIA's C7507 integer vertex attribute error, which can contribute to the white 3D scene in Chapter 1. The compiler fix was reproduced and verified locally. Confirmation on the reporter's RTX 5080 is pending.
- Updated Game Library with installed versions, display and input summaries, per-game release checks, and a mouse and lightgun input test.

Enable **Gamepad (P1 + P2)** under **Settings > Graphics / Input** and save. Press **Menu / Start** to join.

Update from **Updates > Download and install**. For a manual update, extract the Local Builder ZIP, run `Setup.cmd`, and select your existing installation and game files.
