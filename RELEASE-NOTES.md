# HOTD4 Special Local Builder v1.1.0

This Windows desktop update adds optional Home rules and two ways to frame the 3D gameplay at 16:9.

## Home rules

Choose **Settings > Gameplay > Rules > Home** and save before starting Arcade or Chapter Practice.

- G and Kate start with **three lives each** when both are playing. Arcade damage events are assigned to one eligible player at a time. A surviving player can keep playing after their partner runs out of lives.
- Releasing the trigger leaves your magazine as it is. Use your Reload binding or the optional off-screen lightgun reload.
- The original ride camera changes use a short crossfade in Home mode.

**Arcade** is still the default and uses the original shared life bar and trigger-release reload.

## 16:9 gameplay framing

Under **Settings > Graphics / Input > 16:9 Gameplay Framing**, choose:

- **4:3 Expanded** (default) keeps the full vertical view from the arcade's 4:3 mode and shows more at the sides.
- **5:3 Expanded** keeps the tighter vertical view from the arcade's 1280 x 768 mode and also shows more at the sides.

Both presets apply to live 3D gameplay. Prerendered videos play at their original framing.

## Download and update

Download **HOTD4SP-Local-Builder-v1.1.0.zip**, extract it and run **Setup.cmd** with your own supported **HOTD4 Special** arcade dump. To update, select the same dump and your existing installation folder to keep your settings and cabinet saves.

The ZIP contains builder tools and source only. Game assets are processed locally from your dump.

Verified on Windows with both solo seats, simulated co-op, scripted on- and off-screen reload checks, both arcade FOV references, and frame captures of the new camera transitions. The desktop and optional OpenXR builds were compiled. See [BUILD-VERIFICATION.md](https://github.com/davidptrssvea/HOTD-4-Special-recomp/blob/v1.1.0/BUILD-VERIFICATION.md#desktop-home-rules-and-169-gameplay-framing) for coverage and hardware limits.
