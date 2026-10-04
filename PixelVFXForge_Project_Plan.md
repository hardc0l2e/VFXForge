# Pixel VFX Forge — Project Plan & Architecture Specification

## 1. Project Overview

**Pixel VFX Forge** is a standalone, offline-first desktop application for creating procedural pixel-art visual effects.

The application is intended to be:

- Built with **Godot 4.x**
- Completely usable **offline**
- A standalone desktop application after export
- Similar in workflow philosophy to procedural/node-based VFX tools
- Complementary to tools such as Pixelorama, but focused on **procedural pixel VFX generation**
- Extensible through **scriptable/custom GDScript nodes**
- Capable of manual pixel editing after procedural generation
- Godot-friendly for game development
- Initially developed as a **blank independent project**
- Later usable as a production tool for **Haribon ARPG**
- Eventually adaptable to other games and engines

The first implementation should **not depend on Haribon**.

---

# 2. Core Vision

The intended workflow is:

```text
CREATE
  ↓
BUILD NODE GRAPH
  ↓
PROCEDURALLY GENERATE
  ↓
PIXEL-NATIVE RENDER
  ↓
ANIMATE
  ↓
MANUALLY POLISH PIXELS
  ↓
PREVIEW
  ↓
EXPORT
```

The application should combine:

1. Procedural generation
2. Node-based visual authoring
3. Scriptable nodes
4. Pixel-native rendering
5. Frame-based animation
6. Palette control
7. Manual pixel editing
8. Game-ready export

The goal is not to create a clone of an existing application.

The goal is to create an **independent procedural pixel-VFX authoring system**.

---

# 3. Inspiration and Positioning

The project is inspired by the general workflow of tools such as:

- VFXGen
- Pixelorama
- Node-based procedural editors
- Godot's visual/shader graph concepts

The project should **not copy**:

- proprietary source code
- proprietary node implementations
- proprietary recipes
- proprietary artwork
- proprietary UI assets
- protected content or branding

The implementation should be independently designed.

### Conceptual distinction

Pixelorama is primarily:

> Pixel-art creation and animation.

Pixel VFX Forge is primarily:

> Procedural pixel-effect creation and animation.

The tool should combine the strengths of both approaches:

```text
Procedural Generation
        +
Node Graph
        +
Pixel Editing
        +
Animation
        =
Pixel VFX Forge
```

---

# 4. Platform and Runtime Strategy

## Development Engine

Use:

**Godot 4.x**

The application itself is developed as a normal Godot project.

## Finished Application

Users should not need Godot installed.

Godot exports the project into a normal desktop application.

Example:

```text
PixelVFXForge.exe
```

Potential future targets:

```text
Windows
Linux
macOS
```

The first target should be:

**Windows 64-bit**

because this is the primary development environment.

---

# 5. Offline-First Requirement

Offline operation is a core architectural requirement.

The application should not require:

- Login
- Cloud account
- Server
- Internet connection
- Remote rendering
- Cloud AI
- Online asset generation
- Online licensing for basic functionality

All core operations happen locally.

```text
User
  ↓
Pixel VFX Forge
  ↓
Local CPU/GPU
  ↓
Local Project Files
  ↓
Local Export
```

No network dependency should exist in the core application.

Future optional online features can be added later without making them required.

---

# 6. High-Level Architecture

The application should be divided into a reusable core and editor layer.

```text
                         PIXEL VFX FORGE
                                │
              ┌─────────────────┴─────────────────┐
              │                                   │
       PIXEL VFX CORE                         EDITOR UI
              │                                   │
      ┌───────┼────────┐                   ┌──────┼──────┐
      │       │        │                   │      │      │
    Graph  Renderer Animation            Graph  Canvas Timeline
      │       │        │                   │      │      │
      └───────┼────────┘                   └──────┼──────┘
              │                                   │
              └─────────────────┬─────────────────┘
                                │
                           EXPORT SYSTEM
                                │
                 ┌──────────────┼──────────────┐
                 │              │              │
                PNG        Sprite Sheet      Godot
                                             Assets
```

---

# 7. Core Architectural Principle

The **VFX engine must be independent from the editor UI**.

Do not put procedural generation logic directly inside UI controls.

Instead:

```text
Pixel VFX Core
├── Graph Engine
├── Node System
├── Renderer
├── Animation System
├── Palette System
├── Project System
└── Export System

Editor
├── Graph Editor
├── Pixel Canvas
├── Timeline
├── Inspector
├── Preview
└── Asset Browser
```

This makes the core reusable.

Eventually the same core can support:

```text
PixelVFXForge.exe
        +
Haribon Godot Plugin
        +
Future tools/integrations
```

---

# 8. Node-Based VFX Graph

The heart of the application is a custom VFX node graph.

This should be a **custom graph editor**, rather than relying entirely on Godot VisualShader.

Godot's existing visual systems can inform the architecture, but Pixel VFX Forge should have its own node/data model.

Example:

```text
┌─────────────┐
│   Circle    │
└──────┬──────┘
       │
┌──────▼──────┐
│    Burst    │
└──────┬──────┘
       │
┌──────▼──────┐
│  Pixelize   │
└──────┬──────┘
       │
┌──────▼──────┐
│   Palette   │
└──────┬──────┘
       │
┌──────▼──────┐
│  Animate    │
└──────┬──────┘
       │
┌──────▼──────┐
│   Output    │
└─────────────┘
```

---

# 9. Node Categories

Nodes should be categorized.

## Shape Nodes

Examples:

- Circle
- Rectangle
- Line
- Arc
- Ring
- Polygon
- Star
- Burst
- Point
- Custom Shape

## Particle Nodes

Examples:

- Particle
- Particle Burst
- Particle Trail
- Spark
- Debris
- Smoke
- Dust

## Motion Nodes

Examples:

- Move
- Rotate
- Scale
- Expand
- Contract
- Orbit
- Direction
- Velocity
- Gravity
- Turbulence

## Noise/Procedural Nodes

Examples:

- Noise
- Random
- Seed
- Distortion
- Jitter
- Cellular Noise
- Turbulence

## Mask Nodes

Examples:

- Mask
- Threshold
- Multiply
- Add
- Subtract
- Intersect
- Blur
- Expand
- Contract

## Color Nodes

Examples:

- Color
- Gradient
- Palette
- Colorize
- Brightness
- Contrast
- Flash
- Fade

## Pixel Nodes

Examples:

- Pixelize
- Quantize
- Dither
- Pixel Outline
- Pixel Shadow
- Pixel Highlight
- Snap to Grid

## Animation Nodes

Examples:

- Animate
- Curve
- Ease
- Loop
- Ping-Pong
- Frame Offset
- Frame Randomize

## Output Nodes

Examples:

- Frame Output
- Sprite Sheet Output
- Animation Output
- PNG Output
- Godot Output

---

# 10. High-Level Nodes

The system should eventually support reusable higher-level nodes/subgraphs.

Example:

```text
[Fire]
```

internally contains:

```text
Fire
├── Core
├── Glow
├── Sparks
├── Smoke
└── Turbulence
```

But the user can see it as one node:

```text
┌──────────────────┐
│ 🔥 FIRE          │
│                  │
│ Intensity   ███  │
│ Size        ██   │
│ Turbulence  ███  │
└──────────────────┘
```

This allows complex effects to become reusable procedural recipes.

---

# 11. Scriptable Nodes

A major requirement is the ability to create custom nodes through GDScript.

Example conceptual node:

```gdscript
@tool
extends VFXNode

class_name FireBurstNode

@export var radius := 8
@export var intensity := 1.0
@export var seed := 12345

func generate(context):
    # Procedural pixel generation
    pass
```

The editor should expose exported parameters automatically.

Example:

```text
Fire Burst
────────────
Radius       [ 8 ]
Intensity    [ 1.0 ]
Seed         [ 12345 ]
```

Custom nodes should eventually be loadable from a designated directory.

Example:

```text
PixelVFXForge/
    nodes/
        built_in/
        custom/
```

The exact plugin/API system should be designed before implementation.

---

# 12. Deterministic Seed System

Procedural effects should support deterministic seeds.

Example:

```text
Effect: HeavySlash
Seed: 829174
```

If the same:

- graph
- parameters
- seed

are used, the generated result should be reproducible.

The UI should provide:

**Randomize Seed**

so the user can quickly generate variations.

This is essential for procedural asset production.

---

# 13. Pixel-Native Rendering

Pixel rendering is a core requirement.

The tool should not simply render smooth VFX and apply a pixel-art shader afterward.

Preferred pipeline:

```text
Procedural Data
      ↓
Shape Generation
      ↓
Particle / Mask Generation
      ↓
Pixel Rasterization
      ↓
Palette Quantization
      ↓
Frame
```

Supported logical resolutions should include:

- 16×16
- 24×24
- 32×32
- 48×48
- 64×64
- 96×96
- 128×128

Additional custom resolutions should eventually be supported.

Rendering should preserve discrete pixel placement.

Nearest-neighbor scaling should be used for enlarged previews.

---

# 14. Pixel Editing

Procedural generation should be followed by manual pixel editing.

The user should be able to:

- Pencil
- Erase
- Fill
- Line
- Rectangle
- Ellipse
- Select
- Move
- Mirror
- Rotate
- Copy/paste
- Edit palette
- Add/remove pixels
- Edit individual animation frames

This creates the workflow:

```text
Generate
   ↓
Tune
   ↓
Pixel Edit
   ↓
Animate
   ↓
Export
```

---

# 15. Palette System

The application should have a first-class palette system.

Effects should not need arbitrary colors everywhere.

Example:

```text
Haribon Fire Palette

Dark
Shadow
Base
Highlight
White-hot
```

Potential built-in categories:

- Fire
- Water
- Earth
- Wind
- Lightning
- Light
- Shadow
- Poison
- Nature
- Ice
- Arcane
- Blood

Custom palettes must be supported.

Palette swapping should allow an effect to be reused with different visual identities.

Example:

```text
Fire
  ↓
Palette Swap
  ↓
Blue Fire
```

---

# 16. Animation System

The application should have a frame-based animation timeline.

Example:

```text
FRAME     01 02 03 04 05 06 07 08 09 10 11 12

Core      ██ ██ ██ ██ ██ ██ ██ ░░ ░░
Glow      ░░ ██ ██ ██ ██ ██ ██ ██ ░░
Particles ░░ ░░ ██ ██ ██ ██ ██ ██ ░░
Ring      ░░ ░░ ░░ ██ ██ ██ ██ ██ ░░
Debris    ░░ ░░ ██ ░░ ██ ░░ ██ ░░
```

Required initial features:

- Frame selection
- Play
- Pause
- Scrubbing
- FPS control
- Looping
- Frame duplication
- Frame deletion
- Frame reordering
- Copy/paste
- Onion skin
- Frame preview

Later features:

- Curves
- Keyframes
- Easing
- Ping-pong
- Procedural frame timing

---

# 17. Live Preview

The application should provide a live preview.

Changes to node parameters should regenerate the effect and update the preview.

Example:

```text
Change Radius
      ↓
Graph Re-evaluates
      ↓
Renderer Updates
      ↓
Animation Preview Updates
```

The preview should support:

- Zoom
- Pan
- Background selection
- Grid
- Pixel grid
- Checkerboard transparency
- Play/pause
- Frame stepping
- Loop
- FPS display

---

# 18. Proposed User Interface

Conceptual layout:

```text
┌─────────────────────────────────────────────────────────────┐
│ File  Edit  View  Graph  VFX  Export                       │
├────────────┬──────────────────────────────┬─────────────────┤
│ NODE       │                              │ INSPECTOR       │
│ LIBRARY    │           GRAPH              │                 │
│            │                              │ Radius      8   │
│ Shapes     │ [Circle]                     │ Speed      12   │
│ Motion     │     │                        │ Seed    39421   │
│ Color      │     ▼                        │                 │
│ Noise      │ [Burst]                      │                 │
│ Pixel      │     │                        │                 │
│ Output     │     ▼                        │                 │
│            │ [Pixelize]                   │                 │
├────────────┴──────────────────────────────┴─────────────────┤
│                         LIVE PREVIEW                        │
│                                                             │
│                           ✦ ✦                               │
│                         ✦ ✦ ✦ ✦                            │
│                           ✦ ✦                               │
├─────────────────────────────────────────────────────────────┤
│ ◀ ▶  Frame 04 / 12     FPS 24       Loop                  │
├─────────────────────────────────────────────────────────────┤
│ Timeline: 01 02 03 04 05 06 07 08 09 10 11 12             │
└─────────────────────────────────────────────────────────────┘
```

---

# 19. Project File Format

The application should use its own editable project/effect format.

Suggested project structure:

```text
MyFireball/
    project.vfxproj

    effects/
        fireball.vfx

    palettes/
        fire.palette

    assets/
        reference.png

    exports/
```

An individual `.vfx` file should conceptually store:

- Metadata
- Node graph
- Nodes
- Connections
- Parameters
- Seeds
- Animation
- Palette
- Canvas size
- Export settings

The graph must remain editable after saving.

Exporting a PNG must not destroy the procedural source.

---

# 20. Example VFX Project

Example:

```text
fireball.vfx
```

Conceptually:

```text
[Circle]
    ↓
[Expand]
    ↓
[Noise]
    ↓
[Pixelize]
    ↓
[Palette: Fire]
    ↓
[Animate]
    ↓
[Output]
```

Parameters:

```text
Canvas: 32 × 32
Frames: 12
FPS: 24
Seed: 391822
Palette: Fire
```

---

# 21. Export System

The export pipeline should support several formats.

## Image Export

- PNG
- Individual frames

## Sprite Sheets

Potential layouts:

```text
1 × 8
2 × 4
4 × 4
4 × 8
8 × 8
```

The system should automatically calculate layouts based on frame count when requested.

## Animation

Eventually:

- GIF
- APNG

## Game Engine Export

First-class:

**Godot**

Potential outputs:

```text
Texture2D
SpriteFrames
AnimatedSprite2D-compatible data
.tres
```

The export workflow should make it easy to move an effect into a Godot project.

---

# 22. Godot Integration

The application is built with Godot, but the finished tool should be independent from the user's Godot installation.

For development:

```text
Godot
   ↓
Pixel VFX Forge Project
```

For users:

```text
PixelVFXForge.exe
```

For Haribon:

```text
Pixel VFX Forge
       ↓
Godot-compatible export
       ↓
Haribon
```

---

# 23. Future Haribon Integration

The first version must remain independent from Haribon.

Later, create a Haribon-specific style layer.

Possible structure:

```text
Haribon Style
├── Palettes
├── Effect Presets
├── Pixel Resolution
├── Outline Rules
├── Animation Timing
├── VFX Recipes
└── Export Presets
```

Examples:

```text
Haribon/
    VFX/
        SwordSlash.vfx
        CriticalHit.vfx
        Fireball.vfx
        Lightning.vfx
        Heal.vfx
        EnemyDeath.vfx
```

The Forge itself remains general-purpose.

---

# 24. Haribon-Specific Presets

Eventually the Forge could provide:

```text
Haribon Style Pack
```

with:

- Haribon palettes
- Haribon animation defaults
- Haribon effect presets
- Haribon sprite sizes
- Haribon export presets

This should be an optional style/configuration layer rather than a hard-coded dependency.

---

# 25. Initial Effect Generators

The first procedural generators should include:

1. Impact
2. Slash
3. Projectile
4. Explosion
5. Magic
6. Fire
7. Water
8. Earth
9. Wind
10. Lightning
11. Heal
12. Buff
13. Debuff
14. Shield
15. Dash
16. Teleport
17. Landing
18. Dust
19. Sparks
20. Enemy death burst

The first proof-of-concept generator should be:

**Impact**

because it exercises:

- procedural pixels
- particles
- animation
- palettes
- seeds
- frame generation
- sprite-sheet export

---

# 26. Recommended First Generator: Impact

Example graph:

```text
[Random Seed]
       │
       ▼
[Radial Burst]
       │
       ├───────────────┐
       ▼               ▼
   [Sparks]          [Core]
       │               │
       └───────┬───────┘
               ▼
          [Pixelize]
               │
               ▼
           [Palette]
               │
               ▼
           [Animate]
               │
               ▼
            [Output]
```

Parameters could include:

```text
Size
Intensity
Particle Count
Spread
Direction
Duration
Frame Count
FPS
Palette
Seed
```

---

# 27. Proposed Project Folder

Initial source structure:

```text
PixelVFXForge/
│
├── project.godot
│
├── scenes/
│   └── main.tscn
│
├── scripts/
│   ├── main.gd
│   ├── vfx_generator.gd
│   ├── pixel_renderer.gd
│   └── animation_data.gd
│
├── core/
│   ├── graph/
│   ├── nodes/
│   ├── renderer/
│   ├── animation/
│   ├── palettes/
│   ├── project/
│   └── export/
│
├── editor/
│   ├── graph_editor/
│   ├── canvas/
│   ├── timeline/
│   ├── inspector/
│   └── preview/
│
├── generators/
│   ├── impact/
│   ├── slash/
│   ├── projectile/
│   └── explosion/
│
├── palettes/
│
├── presets/
│
├── nodes/
│   ├── built_in/
│   └── custom/
│
└── exports/
```

The exact directory organization may change as implementation proceeds, but the separation of **core**, **editor**, **generators**, and **export** should remain.

---

# 28. Modular System Design

The system should be divided into modules.

## Graph Engine

Responsible for:

- Nodes
- Ports
- Connections
- Graph evaluation
- Graph serialization

## Renderer

Responsible for:

- Pixel rasterization
- Masks
- Shapes
- Particles
- Palette application
- Frame generation

## Animation System

Responsible for:

- Frames
- Timing
- Curves
- Playback
- Looping

## Palette System

Responsible for:

- Palette definitions
- Color mapping
- Palette swapping
- Palette editing

## Project System

Responsible for:

- `.vfxproj`
- `.vfx`
- Save/load
- Autosave
- Recovery

## Export System

Responsible for:

- PNG
- Sprite sheets
- Animation formats
- Godot resources

## Editor

Responsible for:

- Graph UI
- Canvas UI
- Timeline
- Inspector
- Preview
- Asset browser

---

# 29. Undo/Redo

Undo/redo should be designed early.

It should cover:

- Node creation
- Node deletion
- Node movement
- Connection changes
- Parameter changes
- Pixel edits
- Frame changes
- Palette changes

The exact command/history implementation should be centralized rather than implemented independently in each editor panel.

---

# 30. Autosave and Recovery

The standalone application should eventually provide:

- Autosave
- Crash recovery
- Temporary backup
- Recovery prompt
- Recent projects

This becomes particularly important once users create complex VFX graphs.

---

# 31. Asset Browser

Eventually include a local asset/preset browser.

Possible categories:

```text
Effects
├── Impacts
├── Slashes
├── Projectiles
├── Explosions
├── Magic
├── Elements
└── Environment
```

Users should be able to save generated effects as reusable presets.

---

# 32. Reusable Recipes

A procedural effect should be reusable.

Example:

```text
HeavySwordImpact.vfx
```

could be instantiated multiple times with different:

- Scale
- Palette
- Seed
- Timing
- Direction

This allows procedural asset libraries to grow quickly.

---

# 33. General-Purpose Design

Although Haribon is the initial target use case, the Forge should not be hard-coded for a single game.

The underlying engine should support:

```text
Generic Pixel VFX
        ↓
Style Pack
        ↓
Game-Specific Presets
        ↓
Game Export
```

Possible future style packs:

- Haribon
- Fantasy
- Sci-Fi
- Retro
- Arcade
- Minimalist
- Custom User Style

---

# 34. Hardware Targets

The first release should target relatively modest hardware.

## Minimum Target

```text
OS:
Windows 10/11 64-bit

CPU:
Modern 4-core processor

RAM:
8 GB

GPU:
Integrated graphics should be supported

Storage:
Approximately 500 MB for the application
```

## Recommended

```text
CPU:
6+ modern cores

RAM:
16 GB

GPU:
Modern integrated or dedicated GPU

Storage:
SSD
```

The application should not require a high-end GPU.

This is a local procedural graphics application, not an AI image-generation system.

---

# 35. Performance Goals

The editor should prioritize responsive interaction.

Target:

- Real-time graph parameter updates where practical
- Smooth preview playback
- Fast pixel rendering
- Efficient regeneration
- No unnecessary full-graph recomputation

Eventually the graph engine can use dependency tracking so that changing one parameter only recalculates affected nodes.

Concept:

```text
Changed Node
     ↓
Find Dependent Nodes
     ↓
Recalculate Required Branch
     ↓
Update Output
```

---

# 36. Caching

Eventually implement caching for expensive procedural operations.

Potential cache key:

```text
Graph Hash
+
Node Parameters
+
Seed
+
Canvas Size
+
Frame
```

This allows unchanged results to be reused.

Caching should be introduced after the basic graph engine works.

---

# 37. Development Phases

## Phase 1 — Foundation

Create the blank Godot project.

Requirements:

- Godot 4.x
- Main application window
- Basic dock layout
- Canvas
- Zoom
- Pixel grid
- Basic project saving

No Haribon dependencies.

---

## Phase 2 — Node Graph

Implement:

- Node base class
- Ports
- Connections
- Node creation
- Node deletion
- Node movement
- Node inspector
- Graph save/load
- Graph serialization
- Undo/redo

---

## Phase 3 — Procedural Engine

Implement initial nodes:

```text
Shape
Circle
Rectangle
Line
Ring
Burst
Particle
Noise
Transform
Scale
Rotate
Color
Palette
Pixelize
Animation
Output
```

---

## Phase 4 — Pixel Renderer

Implement:

- Logical pixel canvas
- Pixel rasterization
- Palette quantization
- Nearest-neighbor preview
- Transparency
- Pixel grid
- Frame generation

---

## Phase 5 — Animation

Implement:

- Timeline
- Frames
- Playback
- FPS
- Onion skin
- Frame duplication
- Frame deletion
- Looping

---

## Phase 6 — Scriptable Nodes

Implement:

- GDScript node API
- Custom node discovery
- Custom node parameters
- Custom node registration
- Error handling
- Node documentation

---

## Phase 7 — Export

Implement:

- PNG
- Individual frames
- Sprite sheets
- Animation export
- Godot resources
- Godot-compatible SpriteFrames output

---

## Phase 8 — Editor Polish

Implement:

- Menus
- Keyboard shortcuts
- Autosave
- Recovery
- Preferences
- Asset browser
- Preset browser
- Project manager
- Drag and drop
- Better graph navigation

---

## Phase 9 — Standalone Release

Test:

```text
Windows
Linux
macOS
```

Start with Windows.

Produce:

```text
PixelVFXForge.exe
```

Verify that users do not need the Godot editor installed.

---

## Phase 10 — Haribon Integration

Only after the standalone tool is stable:

- Haribon palette pack
- Haribon presets
- Haribon export presets
- Haribon VFX library
- Optional Godot plugin integration

---

# 40. First Proof of Concept

The first milestone should be intentionally small.

The application should be able to:

1. Open a blank project.
2. Create an Impact VFX.
3. Display a node graph.
4. Generate procedural pixels.
5. Animate the result.
6. Scrub through frames.
7. Change parameters.
8. Change the seed.
9. Change the palette.
10. Export a PNG sprite sheet.

If these work, the core architecture has been validated.

---

# 41. Example First User Experience

User launches:

```text
Pixel VFX Forge
```

Clicks:

```text
New VFX
```

Selects:

```text
Impact
```

The Forge creates:

```text
[Seed]
   ↓
[Burst]
   ↓
[Particle]
   ↓
[Pixelize]
   ↓
[Palette]
   ↓
[Animate]
   ↓
[Output]
```

The center preview immediately shows a pixel impact.

The user changes:

```text
Size: 8 → 12
```

The effect updates.

They click:

```text
Randomize Seed
```

A different impact is generated.

They select:

```text
Palette: Fire
```

Then:

```text
Palette: Lightning
```

The same procedural structure becomes visually different.

Finally:

```text
Export → Godot Sprite Sheet
```

---

# 42. Long-Term Vision

The mature application could become a general-purpose procedural pixel-art/VFX authoring environment.

Potential capabilities:

```text
                PIXEL VFX FORGE
                       │
       ┌───────────────┼────────────────┐
       │               │                │
      VFX          Animation         Pixel Art
       │               │                │
    Effects         Frames           Editing
       │               │                │
       └───────────────┼────────────────┘
                       │
                  Asset Export
                       │
        ┌──────────────┼──────────────┐
        │              │              │
      Godot          Unity         Generic
        │
     Haribon
```

Potential future features:

- Procedural sprite generation
- Procedural particles
- Procedural tiles
- Procedural environmental effects
- Character effect helpers
- Game-specific style packs
- Custom node marketplace/library
- Optional community sharing
- Plugin ecosystem

These are **future possibilities**, not requirements for the first version.

---

# 43. Non-Goals for Version 1

Do not initially attempt to build:

- Full general-purpose pixel-art editor
- Full 3D VFX system
- AI image generation
- Online/cloud rendering
- Multiplayer collaboration
- Cloud asset storage
- Complex physics simulation
- Full Unity/Unreal integration
- Haribon-specific hard-coded systems

The first version should focus on:

> **Procedural 2D pixel VFX + node graph + animation + export.**

---

# 44. Architectural Principles

The project should follow these principles.

### Principle 1 — Offline First

Core functionality must work without internet access.

### Principle 2 — Pixel Native

Generate pixels intentionally rather than post-processing smooth graphics.

### Principle 3 — Procedural

Effects should be reproducible and parameter-driven.

### Principle 4 — Node Based

Complex effects should be represented as editable graphs.

### Principle 5 — Scriptable

Advanced users should be able to create custom nodes.

### Principle 6 — Non-Destructive

Keep procedural source graphs separate from exported images.

### Principle 7 — Modular

Core systems should not depend on editor UI.

### Principle 8 — General Purpose

Haribon should be an integration/style layer, not the core architecture.

### Principle 9 — Godot Friendly

Godot should be the first-class export target.

### Principle 10 — Standalone

The finished application should run without requiring the Godot editor.

---

# 45. Final Target

The desired end result is:

> **A standalone Godot-powered procedural pixel VFX editor with a node graph, scriptable nodes, pixel-native rendering, animation editing, palette control, manual pixel refinement, and game-ready export.**

It should feel like:

```text
VFX Generator
      +
Node Graph
      +
Pixel Editor
      +
Animation Editor
      +
Godot Exporter
```

while remaining:

```text
Offline
Standalone
General-purpose
Extensible
Non-destructive
Godot-friendly
```

The application starts independently from Haribon and later becomes a powerful asset-production tool for Haribon ARPG through presets, palettes, recipes, and optional Godot integration.

# 46. Renderer Backend Strategy

Haribon VFXForge should support multiple rendering backends so creators can choose between deterministic pixel export and high-performance real-time previews.

## Pixel CPU Renderer

Use for:

- Deterministic procedural frames
- Manual pixel editing
- PNG and sprite-sheet export
- Reproducible seed-based effects

## GPU Particle Renderer

Use Godot's `GPUParticles2D` for:

- Sparks
- Smoke
- Fire
- Debris
- Magic particles
- High-particle-count previews
- Real-time desktop effects

Particle nodes should expose amount, lifetime, one-shot, emission shape, velocity, gravity, scale, color ramps, and visibility bounds.

## CPU Particle Renderer

Use `CPUParticles2D` when:

- CPU-side control is required
- Physics interpolation is important
- The effect must be baked or inspected per particle
- GPU support is limited

GPU particles remain the preferred desktop preview path unless CPU behavior is specifically required.

## Shader Renderer

Godot `ShaderMaterial` and particle shaders should support:

- Distortion
- Dissolve
- Procedural masks
- Gradient remapping
- Turbulence
- Glow and flash effects
- Custom particle motion
- Vector-style effects

## Hybrid Renderer

Effects may combine backends. For example:

```text
Pixel CPU Core
      +
GPUParticles2D Sparks
      +
Shader Distortion
      ↓
Preview or baked export
```

GPU-only or non-deterministic effects must be clearly identified when they cannot produce reproducible frame exports.

## Renderer Selection

The graph/output system should eventually provide:

```text
Renderer:
- Pixel CPU
- GPU Particles
- CPU Particles
- Shader
- Hybrid
```

The renderer interface should remain independent from editor UI and expose configuration, frame rendering, preview support, and deterministic-export capability.
