# Haribon VFXForge Architecture

## System boundary

The editor UI must remain separate from the reusable VFX core.

```text
Haribon VFXForge
├── Core
│   ├── Graph
│   ├── Nodes
│   ├── Renderers
│   ├── Animation
│   ├── Palettes
│   ├── Projects
│   └── Export
└── Editor
    ├── Graph Editor
    ├── Canvas Viewport
    ├── Timeline
    ├── Inspector
    ├── Preview
    └── Asset Browser
```

## Renderer contract

Every renderer should eventually implement a common conceptual interface:

```text
configure(settings)
render_frame(context, frame_index) -> RenderResult
supports_deterministic_export() -> bool
get_preview_node() -> Node2D or Control
```

`RenderResult` may contain a `PixelCanvas`, an `Image`, a GPU preview node, or an export warning depending on the backend.

## Backend guidance

- Use pixel CPU rendering for deterministic sprite exports.
- Use `GPUParticles2D` for desktop preview performance and high particle counts.
- Use `CPUParticles2D` when physics interpolation or CPU-side baking is required.
- Use `ShaderMaterial` and particle shaders for distortion, masks, turbulence, and procedural GPU motion.
- Use hybrid graphs when a pixel core needs GPU sparks, glow, or distortion.
- Configure particle visibility bounds.
- Use `restart()` for one-shot particle reuse instead of immediately toggling emission after completion.
- Keep trail systems in global coordinates when trails must remain behind moving objects.

## Viewport model

The UI uses responsive containers. The canvas uses its own transform:

```text
screen position
    ↓ inverse viewport transform
canvas position
    ↓ integer snapping
logical pixel coordinate
```

Zoom, pan, fit, and 1:1 view must affect the canvas transform only, not the dock UI.

## Persistence

Project files must preserve:

- Version number
- Canvas size
- Graph nodes and connections
- Renderer settings
- Seed values
- Animation frames
- Manual pixel edits
- Palette data
- Export settings

Loading must validate the version and provide migration or a clear error.

## General principles

- Offline-first
- Pixel-native where pixel output is requested
- Deterministic seeds for reproducible exports
- Non-destructive procedural source
- General-purpose core, Haribon-specific style packs
- Small, testable modules
- Evidence before completion claims
# Graph UI principles

Haribon VFXForge follows a hybrid node UI inspired by Pixel Composer, Blender
node editors, and Godot VisualShader:

- Core parameters live inside each node so the graph remains useful without
  constantly switching to the Inspector.
- The Inspector remains the place for advanced settings, metadata, and future
  modulation/keyframe controls.
- Connections stay visible through typed ports and are treated as the flow of
  values through the renderer.
- Nodes may expose compact inline controls and remain selectable/draggable.
- Palette and output nodes expose resource/format choices directly in the
  graph while retaining file dialogs for fallback workflows.
