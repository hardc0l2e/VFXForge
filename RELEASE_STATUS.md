# Haribon VFXForge — Release Status

Last verified: 2026-10-04 (Asia/Taipei)

## Verified

- Godot 4.7.2 project starts headlessly without script parse errors.
- Automated suite: **63 passed, 0 failed, 0 skipped**.

Added production-oriented presets: Fireball Projectile, Lightning Sideways,
and Lightning Downward. They generate distinct directional frames and use the
existing glow, mask, texture, pixelize, and export stages.

The CPU compositing path now supports an additive glow stage for Glow Impact
and Hybrid outputs, preserving the core while producing a visible halo.

A reusable SubViewportBaker now captures transparent RGBA frames from live
Godot effects and converts them to nearest-neighbor PixelCanvas frames. It is
ready for integration with GPU particle, shader, and 3D demo scenes.

The GPU particle bake service now builds an isolated transparent GPUParticles2D
burst and routes it through the capture bridge. Output-node integration is the
next step; until then it remains an explicit backend service.
- SpriteFrames validation scene launches headlessly.
- SpriteFrames validation discovers preset-specific exports.
- Projectile, Spark Burst, and AOE Attack graphs load into the editor.
- Their deterministic pixel previews are generated and export naming is unique.
- PNG palette discovery, Haribon style packs, graph editing, node deletion,
  timeline playback, and 1920×1080 default layout are covered by implementation
  tests or startup checks.
- `git diff --check` passes.

## Manual release checks

Run the editor normally and verify at 1920×1080:

1. Select Projectile, Spark Burst, and AOE Attack; confirm graph, preview, and
   timeline update together.
2. Play each preset and change FPS to 2, 4, and 10.
3. Export PNG frames, sprite sheet, and SpriteFrames for each preset.
4. Open `scenes/sprite_frames_validation.tscn` with the exported resource.
5. Resize the window and verify graph clipping, canvas coordinates, palette
   controls, and timeline visibility.

## Release gate status

The matching Godot 4.7.2 Windows templates are installed and the release export completed successfully. Verified artifacts:

`C:/Users/rnartos/AppData/Roaming/Godot/export_templates/4.7.2.stable`

- `exports/build/HaribonVFXForge.exe` (109,196,800 bytes)
- `exports/build/HaribonVFXForge.pck` (2,879,944 bytes)
- Export profile baseline: 1920×1080
- Exported executable launches successfully with `--headless --quit-after 2`.

Remaining release checks are manual: inspect the exported app in a normal window, test resizing and the three presets, then verify on a clean user profile or machine.

Pixelize conversion now uses the graph resolution for exported PNG frames,
sprite sheets, and SpriteFrames through nearest-neighbor frame baking. The
editor preview remains a 32×32 authoring canvas; output resolution is separate.

Recent fixes: every built-in preset now generates a visible preview; File →
Exports groups the individual exporters and provides All Exports; native
window borders, resizing, and standard desktop controls are enabled.

AOE ring expansion is clamped inside the canvas with a regression test for
all four canvas edges.

The AOE radius control is now passed into preview generation and changes the
ring size deterministically.

3D authoring slice: `scenes/vfx3d_fireball_demo.tscn` now provides an
orthographic-camera fireball with a distorted shader core, additive glow shell,
GPUParticles3D sparks, a separate ember trail, and a custom particle shader.
`core/vfx_bake_profile.gd` defines serializable
resolution, frame, FPS, supersampling, and output settings for the upcoming
bake pipeline.

## After the release gate

Once packaging is verified, continue in this order:

1. Assisted runtime/debug pass and multi-resolution coordinate verification.
2. Typed custom-node authoring and a sandboxed custom-script API.
3. Advanced vector authoring with deterministic vector-to-pixel baking.
4. Richer timeline tracks, interpolation modes, and event markers.
5. Project-manager polish and expanded Haribon style-pack workflows.

Do not mark production-ready until the release gate and the manual runtime
checklist are both complete.

Latest graph-layer update:
- Pixelize presence is now observable: removing the node disables output
  upscaling and exports the native canvas resolution.
- Mask nodes apply a radial alpha mask to generated frames.
- Texture nodes can load a PNG through the inspector and apply its alpha as a
  frame mask. Both `res://` project assets and filesystem paths are accepted.
- The remaining production gap is GPU/shader/3D capture into the same frame
  pipeline; those renderers still require the planned SubViewport bake bridge.
Editor integration now exposes “Bake GPU Sparks to Frames”: a real transparent
GPUParticles2D burst is captured, converted to PixelCanvas frames, processed
through Mask/Texture/Glow, and left in the normal export pipeline.
