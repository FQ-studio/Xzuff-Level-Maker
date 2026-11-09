# Xzuff Level Maker

A 2D platform game and level-building prototype made with **Godot 4** and **GDScript**.

## Current prototype

- Main menu and 2D platform play/test scene
- 48 × 12 grid-based level editor with horizontal scrolling
- Erase, ground, brick, hazard, castle, regular enemy, and final boss tools
- Save and load levels locally on the device
- Automatic expansion of older 24-column saved levels to 48 columns
- Player movement, jumping, idle/run/jump visual animation, and respawn
- Smooth player-follow camera with level bounds
- Optimized horizontal runs of matching tile collision shapes
- Final boss with three stomp hits before defeat in standard rounds
- Weapon Round Bowser with independent Armor (1), Jetpack (1), and health (3) segments
- Bowser weapon-round AI: timed jetpack flight and aimed fire-pistol projectiles
- Player weapon shots can target Armor (1), Jetpack (2), or Bowser health (3)
- GitHub Actions workflow for headless Godot validation

## Controls

- Move: Left / Right arrow keys
- Jump: Space / Enter
- Weapon Round: hold F to fire; select target with 1 (Armor), 2 (Jetpack), or 3 (Bowser health)
- Editor: choose a tool, then tap/click a grid cell; swipe horizontally to reach later columns

## Run

Open this folder in Godot 4 and run the project.

## Asset policy

Use original Xzuff characters and assets, or third-party assets whose licenses explicitly permit the intended use. Keep each asset's source and license information in the repository. Do not include Nintendo characters or sprites without permission.

## Status

Early playable prototype. GitHub Actions checks project import/startup in headless mode; this is not a substitute for manual gameplay testing on a device.
