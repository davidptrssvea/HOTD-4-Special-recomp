# HOTD4 Special Local Builder v1.1.1

This Windows desktop update reduces rendering overhead and adds a one-click graphics preset for slower PCs.

- **Settings > Apply 720p Performance** saves a 1280 × 720 internal render resolution and turns off MSAA and anisotropic filtering. That is 56% fewer pixels per frame than 1080p. Borderless mode still fills the display. For a lower render resolution, choose **960 × 540** under **Render Resolution** and save.
- The desktop runtime and OpenGL calls use optimized Release builds. With MSAA off, ordinary gameplay frames copy directly to the window. Home-mode ride crossfades still use their existing blend pass.
- Home and Arcade rules, both 16:9 gameplay framing modes, and selectable solo controls are available in this build.

In one 3,650-frame 1080p comparison against v1.1.0, the updated desktop build used about **7% less process CPU time** on a Core i5-13400F and RTX 4070 Ti. Testing on older hardware remains open.

Download **HOTD4SP-Local-Builder-v1.1.1.zip**, extract it and run **Setup.cmd** with your supported HOTD4 Special arcade dump. For an update, select that dump and your existing installation folder to keep your settings and cabinet saves. After selecting the preset, start the game to use it.

The ZIP contains the local builder and source. Setup compiles the game from your own dump. The optional OpenXR build is experimental. [Build verification](https://github.com/davidptrssvea/HOTD-4-Special-recomp/blob/v1.1.1/BUILD-VERIFICATION.md#v111-desktop-performance)
