# HOTD4 Special v1.1.12 - Integrated character shader fix

- Integrated the confirmed Matrix Index Shader Test correction into regular Windows builds, so future updates retain it.
- Fixed incorrect animation matrix indices that could make enemy body parts disappear or become displaced on affected OpenGL drivers.
- Preserved the earlier white-screen shader compatibility fixes, along with existing gamepad, lightgun, co-op and Special-specific features.
- Added a shader regression test to source CI and the release checks. The correction is also included when building the optional OpenXR OpenGL target.

This is the full Windows Local Builder. No game assets, arcade executable, generated game code or prebuilt game executable are included. Setup builds locally using your own supported HOTD4 Special arcade dump.

Update through **Updates > Download and install**, then use the normal **Play HOTD4 Special** launcher. The separate Matrix Index Shader Test launcher is no longer needed after updating.

For a manual update, extract **HOTD4SP-Local-Builder-v1.1.12.zip**, run **Setup.cmd**, select your same Special dump and existing installation folder. Your saved settings and cabinet data are preserved.

Validation includes the reporter's confirmation of the test fix, local GPU checks of legacy attribute input and palette blending, compilation of desktop and OpenXR shader paths, source-package integrity checks, and automated Windows installer/updater/input tests. Physical VR headset testing was not performed for this release.
