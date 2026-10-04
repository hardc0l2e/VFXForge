# Haribon VFXForge Roadmap

## Vision

Haribon VFXForge is a standalone, offline-first procedural 2D VFX authoring tool built with Godot 4.7.2. It combines the procedural graph mindset of Blender Geometry Nodes with pixel and vector VFX workflows inspired by tools such as Pixelorama and VFXGen.

## Rendering strategy

Haribon VFXForge will support multiple renderer backends:

| Backend | Primary use |
|---|---|
| Pixel CPU | Deterministic pixel frames, editing, PNG export |
| GPU particles | Fast desktop previews and real-time effects |
| CPU particles | Compatibility, physics-interpolated motion, baking |
| Shader | Distortion, masks, procedural motion, vector-style effects |
| Hybrid | Combining pixel, particles, and shaders in one graph |

GPU particles and shaders are preview-oriented unless their output can be deterministically baked. Export must clearly identify effects that depend on non-deterministic or GPU-only behavior.

## Milestones

### Foundation

Godot project, responsive editor shell, pixel canvas, branding, local Git.

### Procedural prototype

Impact generator, seeds, palettes, animation, sliders, manual pixel editing.

### Asset pipeline

Project files, frame data, PNG exports, sprite sheets, Godot `SpriteFrames`.

### Renderer system

Renderer abstraction and native Godot `GPUParticles2D`, `CPUParticles2D`, and shader support.

### Graph system

Ports, connections, evaluation, serialization, inspector properties, undo/redo.

Current graph status: the standard Seed → Burst → Pixelize → Palette → Output
chain evaluates and serializes; nodes expose inline controls and typed
connection metadata. Named multi-slots, graph navigation, connection editing,
and undo/redo remain to be implemented.

### Content system

Reusable presets, generators, palettes, asset browser, custom nodes.

### Release

Autosave, recovery, preferences, packaging, documentation, and verification.

## Non-goals for version 1

- Full 3D VFX authoring
- Cloud rendering
- Required online services
- AI-generated assets
- Hard-coded Haribon game dependencies
- Full replacement for a general pixel-art editor
