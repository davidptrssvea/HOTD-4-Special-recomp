# HOTD4 Special Local Builder v1.0.2

Full Windows release with selectable desktop solo controls for **G (P1)** or **Kate (P2)**, all previous Special fixes and optional experimental OpenXR.

- Open **Settings > Gameplay > Solo Player**, choose your character and **Save**. Your primary mouse or Raw Input lightgun, crosshair, shooting, reload/shake and grenade controls automatically operate that seat. G/P1 remains the default.
- The same option is available in **Pause > Settings > Gameplay**. Restart Arcade/Chapter to apply changes made during play.
- Special's shared ride Start/credits and shared life remain intact. Default **5/C** and **1/Enter** still work. Both native player objects remain present; this is an input-seat choice, not a change to the story or native life rules. Mixed co-op/Parsec modes retain their normal P1/P2 assignments and disable the override. OpenXR controller assignments are unchanged.
- Retains the shared HOTD4/Special menu, robust Setup download/dependency recovery, 16:9 and HUD/ammo fixes, path previews, supported cutscene skips, mouse-shake/Justice fixes, Sinden/crosshair settings, off-screen lightgun reload, optional enhanced blood and frame-time logging.

Download **HOTD4SP-Local-Builder-v1.0.2.zip**, extract it and run **Setup.cmd** with your own supported **Special** arcade dump. To update, choose the same dump and existing installation folder. Settings and cabinet saves are preserved; select Kate after updating if desired. Normal HOTD4 requires its separate builder/dump and offers James/P1 or Kate/P2 from v1.3.12.

No arcade ELF, textures, movies, audio, lifted game code, prebuilt game executable or cabinet save is distributed. Everything is built/processed locally from your own dump. See README for supported SHA-256 and Windows/system requirements, and BUILD-VERIFICATION.md for exact test coverage and hardware limits.

Tested: four native desktop input runs, Justice mouse-shake positive/negative checkpoint cases, saved/reopened launcher choice and co-op isolation, cached desktop/OpenXR update preservation, Windows PowerShell recovery/library tests, runtime regressions and source-only package validation. Physical lightgun/headset testing was not performed for this update.
