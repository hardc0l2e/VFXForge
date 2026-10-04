# Haribon VFXForge Kanban

## Project status

Haribon VFXForge is a Godot 4.7.2 standalone procedural 2D VFX editor. The current prototype has a working procedural Impact effect, animation preview, pixel painting, palette selection, project serialization, PNG/sprite-sheet export, and a basic graph viewport.

## Done

- [x] Godot 4.7.2 project foundation
- [x] Haribon VFXForge branding
- [x] Dark UI with `#78ffd9` accent
- [x] Responsive windowed layout
- [x] Procedural Impact generator
- [x] Deterministic and manual seeds
- [x] Fire and Ice palettes
- [x] Palette color grid
- [x] LMB paint and RMB erase
- [x] Animation playback and frame scrubbing
- [x] Frame duplication and deletion
- [x] Project save/load with manual pixel data
- [x] PNG frame export
- [x] Horizontal, vertical, and grid sprite-sheet export
- [x] Initial Godot SpriteFrames export
- [x] Local Git repository
- [x] Basic graph nodes with selection and dragging
- [x] Inline node controls for Seed, Burst, Pixelize, Palette, and Output
- [x] Typed connection metadata and duplicate-edge protection
- [x] PNG palette preset folder and global dropdown

## In progress

- [ ] Normal-window verification of exported SpriteFrames and all presets
- [ ] Coordinate verification at multiple window sizes
- [ ] Fix local Git checkpoint permissions
- [x] Add generic graph/node parameter authoring UI for discovered nodes

## Block 3 — Asset pipeline completion

- [x] Project validation and migration versions
- [x] Clear load/save error messages
- [x] Project metadata: name, canvas size, FPS, palette, export settings
- [x] Export options dialog with format, columns, and padding
- [x] Sprite-sheet padding and layout settings backend
- [x] Verify SpriteFrames validation scene launches and discovers preset exports

## Block 4 — Renderer foundation

- [x] Define renderer interface: Pixel CPU, GPU particles, CPU particles, Shader, Hybrid
- [x] Add `GPUParticles2D` preview renderer
- [x] Add deterministic CPU particle backend foundation
- [x] Add `ShaderMaterial` preview effects
- [x] Add renderer selection to graph/output settings
- [x] Bake CPU particle preview results into deterministic pixel frames where possible
- [x] Add renderer capability warnings for non-deterministic effects

## Block 5 — Real node graph

- [x] Interactive input/output ports
- [x] Editable connections
- [x] Graph evaluation foundation for Seed, Burst, Pixelize, Palette, and Output
- [x] Node property inspector foundation and inline controls
- [x] Graph serialization of node parameters, positions, and connections
- [x] Graph undo/redo
- [x] Renderer nodes and output nodes

## Block 6A — Graph usability

- [x] Explicit node/port connection records with backward-compatible loading
- [x] Named multi-input/output slots
- [x] Type labels and connection compatibility feedback
- [x] Right-click disconnect
- [x] Duplicate-edge protection
- [x] Connection replacement and reconnect
- [x] Reroute nodes
- [x] Graph zoom, pan, snapping, fit, and reset view
- [x] Graph undo/redo

## Block 6 — Graph evaluation and verification

- [x] `GraphEvaluator` module with deterministic parameter extraction
- [x] Graph state round-trip serialization support
- [x] Graph validity reporting for the standard Seed → Burst → Pixelize → Palette → Output chain
- [x] Headless Godot startup verification after graph changes
- [x] Run the automated test suite after graph changes
- [x] Add filesystem-backed save/load/export fixture tests
- [x] Add filesystem-backed project codec round-trip tests
- [x] Add deterministic PNG frame and sprite-sheet image export tests
- [x] Add separate SpriteFrames playback validation scene
- [x] Add SpriteFrames playback fixture resource
- [x] Add tested multi-frame SpriteFrames resource exporter
- [x] Renderer capability contract
- [x] Deterministic CPU particle backend foundation
- [x] Built-in preset library foundation
- [x] Renderer selector and capability status UI
- [x] Built-in preset selector UI
- [x] CPU particle preview integration
- [x] Output-node renderer serialization and export capability warning
- [x] Scalar/vector field math foundation and tests
- [x] Data-driven node registry and search foundation
- [x] Deterministic noise and procedural field foundation
- [x] Numeric keyframe track foundation and interpolation test
- [x] Core pixel line, rectangle, fill, and mirror tools with tests
- [x] Palette-set serialization and color editing foundation
- [x] Vector line, Bezier, and polygon geometry foundation
- [x] Custom node definition and validation contract
- [x] Core VFX preset recipes and parameter defaults
- [x] Project schema validation and migration foundation
- [x] Preferences and recovery storage foundation
- [x] Preferences loading and autosave recovery integration
- [x] Registry-backed node insertion actions
- [x] Functional scalar/vector/noise graph-node evaluation
- [x] Renderer-node capability evaluation
- [x] Named parameter animation-track foundation
- [x] Timeline intensity keyframe integration
- [x] Bezier vector preview overlay
- [x] Pixel/vector alpha compositing foundation and test
- [x] Windows export profile and release checklist
- [x] Add palette editing and PNG save dialog; palette-set browser remains pending
- [x] Make the Output node route Graph Output to PNG, SpriteSheet, or SpriteFrames
- [x] Add deterministic generator and export-plan tests
- [x] Verify main scene launches after asset-pipeline changes
- [x] Load custom PNG palettes and display their swatches

## Block 7 — Pixelorama-style viewport

- [x] Fit canvas and keyboard view controls
- [x] 1:1 view and reset foundation
- [x] Zoom toward cursor foundation
- [x] Middle-mouse and space-drag pan foundation
- [x] Integer zoom presets foundation
- [x] Grid visibility thresholds foundation
- [x] Canvas centering and reset view foundation
- [ ] Coordinate tests at multiple window sizes

## Block 8 — Pixel editing

- [x] Pencil tool
- [x] Eraser tool
- [x] Line tool
- [x] Rectangle tool
- [x] Fill tool
- [x] Selection rectangle interaction and drag-move foundation
- [x] Mirror and flip foundation
- [x] Onion skin preview foundation and toggle
- [x] Complete undo/redo history for pixel edits

## Block 9 — Reusable content

- [x] Preset recipe save/load foundation
- [x] Slash generator recipe
- [x] Explosion generator recipe
- [x] Projectile generator recipe
- [x] Fire generator recipe
- [x] Lightning generator recipe
- [x] Smoke and magic generator recipes
- [x] Preset selector foundation
- [x] Node categories and search foundation

## Block 10 — Scriptable nodes

- [x] Custom node runtime executor contract; unrestricted GDScript execution remains pending
- [x] Custom node discovery and validation backend
- [x] Exported parameter support through generic inspector controls
- [x] Validation and error reporting for JSON node definitions
- [x] Node documentation panel foundation

## Block 11 — Release polish

- [x] Haribon style packs and palettes
- [x] Project manager recent-project data and File menu integration
- [x] Autosave and recovery foundation
- [x] Preferences and keyboard shortcuts foundation
- [ ] Windows standalone packaging
- [ ] Full feature verification
- [x] Restore native resizable window controls and File → Exports organization
- [x] Ensure every built-in preset produces a visible preview
- [x] Add first 3D fireball authoring slice with GPUParticles3D and shader
- [x] Mix separate 3D core, glow, spark, and trail layers
- [x] Add serializable 3D bake profile contract
- [x] Make Pixelize resolution affect exported frame dimensions
- [x] Make removing Pixelize disable its output-resolution stage
- [x] Apply radial Mask node alpha to generated frames
- [x] Add Texture node PNG picker and alpha-mask application
- [ ] Capture GPU particles, shaders, and 3D effects through a SubViewport bake bridge
- [x] Add additive glow compositing for Glow Impact and Hybrid output
- [x] Add reusable transparent SubViewport frame-capture bridge
- [x] Add isolated GPUParticles2D bake service using the capture bridge
- [ ] Connect SubViewport capture to Output exports and renderer selection
- [x] Add Fireball Projectile production preset
- [x] Add Lightning Sideways and Lightning Downward production presets
- [ ] Capture GPU particles and shader output into bakeable frame sequences

## Upcoming blocks — next session

### Release gate

- [x] Install Godot 4.7.2 Windows export templates.
- [x] Produce `exports/build/HaribonVFXForge.exe` from `export_presets.cfg`.
- [x] Smoke-test the standalone EXE with a headless launch.
- [ ] Launch the standalone EXE on a clean machine or clean user profile.
- [ ] Verify packaging includes palettes, custom nodes, exports, and no editor-only dependency.

### Assisted runtime verification

- [ ] Run the normal-window checklist at 1920×1080 and a resized narrow window.
- [ ] Verify Projectile, Spark Burst, AOE Attack, Impact, and Haribon style packs.
- [ ] Verify play/pause, FPS 2/4/10, scrubbing, frame duplication/deletion, and onion skin.
- [ ] Verify graph add/delete/drag/zoom/pan/reconnect/reroute and inline controls.
- [ ] Verify canvas coordinates, painting/erasing, selection move, undo/redo, and palette editing.
- [ ] Verify PNG, sprite-sheet, and SpriteFrames exports for each major preset.

### Authoring expansion after release gate

- [ ] Expand custom-node property editing and typed parameter widgets.
- [ ] Define a sandboxed custom GDScript runtime API; do not enable unrestricted execution.
- [ ] Add advanced vector authoring and vector-to-pixel baking controls.
- [ ] Add richer timeline tracks, interpolation modes, and event markers.
- [ ] Add full project manager UI and recent-project management polish.
- [ ] Add more Haribon style packs and palette import/export workflows.

## Working rule

Each block should end with a working, testable build and a Git checkpoint. Do not add Haribon-specific runtime dependencies to the core renderer.
- [x] Expose GPU particle capture as exportable editor frames
