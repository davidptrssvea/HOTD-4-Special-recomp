# HOTD4 Special v1.1.10 - Updater and launcher fixes

- Retry temporary Windows file replacement errors during updates. If a file still cannot be replaced, the updater preserves the existing installation where possible and logs the affected path and Windows error code in `update-error.log`.
- Show the installed builder version directly in the main menu.
- Fix **Free Play (unlimited credits)** and **Mute Start and coin sounds** when a Windows settings path contains non-ASCII characters.
- Fix two OpenGL shader errors that can cause a white 3D scene on NVIDIA drivers.

If the previous updater failed, close the game and launcher, extract this release's Local Builder ZIP into a separate folder, and run `Setup.cmd` against your existing installation folder. Use the same arcade dump to keep your settings and saves. You can also use **Updates > Download and install** from a working launcher.
