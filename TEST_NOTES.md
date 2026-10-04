# Haribon VFXForge — Verification Notes

Last verified: 2026-10-04

## Automated baseline

Command:

```powershell
& 'C:\godot\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'C:\projects\VFXForge' -s res://tests/run_headless.gd
```

Result: **63 passed, 0 failed, 0 skipped**.

Directional production presets are covered: Fireball Projectile, Lightning
Sideways, and Lightning Downward generate distinct visible frame sequences.

Added compositor coverage for additive glow while preserving the source core.

The latest run also verifies radial masking and graph tracking for Pixelize,
Mask, and Texture nodes. The editor project scan completed without script
parse errors.

Covered additions:

- deterministic seeded generation and changed-seed variation;
- PNG palette loading and color deduplication;
- filesystem project save/load round-trip and invalid JSON rejection;
- PNG and sprite-sheet dimensions and integer pixel scaling;
- multi-frame Godot SpriteFrames resource generation;
- renderer capability contracts and deterministic CPU particles;
- built-in preset presence and renderer selection metadata;
- line, rectangle, fill, and palette-set behavior;
- visible preview generation for every built-in preset, including Slash,
  Explosion, Fire, Lightning, Smoke, Magic, and Glow Impact;
- AOE ring boundary regression coverage and explicit windowed-mode startup;
- AOE radius control changes the generated ring size;
- 3D fireball demo scene loads headlessly with GPUParticles3D and shader;
- 3D fireball mixes shader core, additive glow, sparks, and a separate trail;
- 3D bake profile serialization preserves resolution, timing, camera scale,
  and supersampling settings;
- pixel edit undo/redo history behavior;
- rectangular pixel selection capture, clear, paste, and move behavior;
- onion-skin opacity and adjacent-frame overlay behavior;
- project startup/scene compilation after canvas selection integration;
- selection drag-move integration compiles and preserves the automated baseline;
- editable frame count/FPS timeline controls and FPS-aware SpriteFrames output;
- multiple named parameter animation tracks and playback sampling;
- custom-node JSON discovery, validation, and malformed-entry reporting;
- discovered custom nodes are exposed as addable node-library entries;
- malformed project dimensions, frame arrays, and FPS values are rejected with
  validation errors;
- palette colors can be added without duplicates and removed by index;
- seeded CPU particle positions can be baked into deterministic pixel frames;
- canvas keyboard view controls compile with fit, 1:1, and reset behavior;
- final startup audit fixed a Godot 4.7.2 `Rect2i` API compatibility issue in
  selection movement;
- generic numeric/text inspector controls compile for discovered custom nodes;
- custom-node descriptions serialize and display through the inspector path;
- edited palettes can be saved and loaded as row-oriented PNG files;
- palette save backend is connected to a filesystem Save Palette dialog;
- checked-in `custom_nodes/vector_offset.json` exercises discovery and inspector
  authoring in a fresh project;
- custom-node runtime input validation and executor contract are tested without
  enabling unrestricted script execution;
- sprite-sheet padding is supported and dimension-tested;
- normal-window validation scene launches without script errors and discovers
  preset-specific SpriteFrames exports;
- graph output now exposes format, columns, and padding through an export dialog;
- recent-project ordering and deduplication are covered by a project-manager
  foundation test;
- File menu recent-project entries are wired to project loading;
- node deletion removes attached connections and remaps graph indices;
- node deletion copies filtered graph state safely into typed runtime arrays;
- socket colors are stable by data type rather than input/output direction;
- Projectile, Spark Burst, and AOE Attack presets expose construction recipes;
- playback timing now advances frames from elapsed time and honors the FPS field;
- color-picker popup/panel styling uses an opaque dark background for readable HSV,
  HSL, RGB, and swatch controls;
- schema migration, preferences, recovery path, and alpha compositing;
- scalar/vector math, procedural fields, graph evaluation, node registry,
  keyframes, parameter animation, custom-node validation, and vector geometry.

## Known expected warnings

- `user://logs/godot.log` may be unavailable in headless mode.
- Loading the PNG fixture directly emits Godot's imported-image warning.
- The invalid JSON test intentionally logs a parse error.
- Renderer leak warnings may appear during headless shutdown.

These warnings do not count as failures. Parse errors in project scripts,
failed assertions, or a non-zero test summary do count as failures.

## Manual verification still required

- Run the main scene in a normal desktop window and verify responsive layout at
  1920×1080 and a resized narrow window. The supported default baseline is
  1920×1080 so the graph, preview, timeline, and palette remain visible.
- Verify graph zoom, clipping, crisp labels, node dragging, reconnect,
  reroutes, and `F`/`0` shortcuts.
- Export a multi-frame SpriteFrames resource and play it in
  `scenes/sprite_frames_validation.tscn`.

The validation scene also launches headlessly without script errors. Its
fixture-backed visual playback still needs a normal-window inspection.

## Release audit result

The matching Godot 4.7.2 Windows templates are now installed. The release export produced `exports/build/HaribonVFXForge.exe` and `exports/build/HaribonVFXForge.pck`; the exported executable also passed a headless launch smoke test. Normal-window and clean-machine verification remain manual follow-ups.
- Verify GPU particles and shaders remain clearly marked preview-only and that
  deterministic pixel export remains available.
- Perform a clean Windows export using `export_presets.cfg`.

## Current phase

The project is past the foundation implementation phase. The next phase is
assisted debugging and feature fixing: manual runtime checks, export validation,
and closing the remaining authoring gaps (full canvas navigation, selection
movement, complete timeline, richer node parameter editing, custom-node
discovery, and production packaging).
The GPU bake editor integration compiles successfully; the full suite remains
at 63 passed, 0 failed, 0 skipped.
