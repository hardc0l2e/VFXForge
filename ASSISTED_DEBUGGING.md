# Haribon VFXForge — Assisted Debugging Phase

Last updated: 2026-10-04

## Verified baseline

- Godot 4.7.2 headless startup succeeds.
- Automated suite: **63 passed, 0 failed, 0 skipped**.

Current verified graph behavior: Pixelize changes exported resolution and is
disabled when removed; Mask applies radial alpha; Texture loads PNG alpha from
the inspector and applies it to generated frames.
- SpriteFrames validation scene launches headlessly without script errors.
- Project script scan succeeds during export initialization.
- `git diff --check` succeeds.
- Known headless warnings are documented in `TEST_NOTES.md`.
- Custom JSON nodes have validated parameters, descriptions, and inspector
  controls; runtime GDScript node execution remains intentionally unimplemented.

## Implemented foundations

- Responsive dark editor shell with Haribon branding and `#78ffd9` accent.
- Pixel painting/erasing, line/rectangle/fill tools, palette selection/editing,
  selection capture/move, onion skin, undo/redo, zoom/pan/fit/reset.
- Deterministic generators, CPU particle baking, GPU/shader preview contracts,
  vector preview, alpha compositing, and graph field evaluation.
- Graph dragging, typed ports, reconnect/reroute, zoom/pan, snapping, fit/reset,
  inline controls, custom JSON-node discovery, and graph undo/redo.
- Project migration/validation, metadata persistence, autosave/recovery,
  PNG/sprite-sheet/SpriteFrames export, export options dialog, and FPS-aware
  timeline playback.

## Manual assisted-debugging checklist

1. Run the editor in a normal desktop window at 1920×1080, then resize it to a
   narrow window. The supported default baseline is 1920×1080.
2. Verify canvas coordinates while zooming, panning, fitting, and resizing.
3. Verify selection drag-move, onion skin, undo/redo, and frame changes visually.
4. Verify graph clipping, crisp labels, node controls, reconnect, and custom-node
   buttons using a sample file under `res://custom_nodes`.
5. Export PNG frames, a sprite sheet, and multi-frame SpriteFrames; play the
   result in `scenes/sprite_frames_validation.tscn` in a normal window.
6. Confirm preview-only warnings for GPU particles, shaders, and Hybrid output.

## Consolidated upcoming blocks

- Inspect the exported Windows EXE in a normal window at 1920×1080 and verify resizing behavior.
- Complete normal-window verification of all presets, exports, graph editing,
  canvas editing, timeline playback, and responsive layout.
- Perform clean-machine packaging verification.
- Then expand typed custom-node authoring and a sandboxed runtime API.
- Then add advanced vector authoring and deterministic vector-to-pixel baking.
- Then add richer timeline tracks, interpolation, and event markers.
- Then polish the project manager and extend Haribon style packs/palette workflows.

## Current release position

The Windows export templates are installed and the release EXE/PCK export has been verified. Do not mark the project production-ready until the manual runtime checklist and clean-machine packaging verification are complete.
