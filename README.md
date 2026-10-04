# Haribon VFXForge

A standalone, offline-first **VFX authoring tool for games**, built with Godot 4.7.2 and
exporting to Godot's built-in shader and particle tooling.

It takes the node-graph authoring model from Blender's Geometry Nodes and applies it to
game VFX: build a graph, generate deterministically from a seed, animate, hand-polish, then
export game-ready assets.

```
BUILD NODE GRAPH → PROCEDURALLY GENERATE → RENDER
→ ANIMATE → MANUALLY POLISH → PREVIEW → EXPORT
```

**Scope of ambition:** 2D (vector, raster, and pixel-based effects) and 3D, targeting Godot's
built-in shaders. **The deterministic pixel path is the current priority** and is the most
mature part; 3D is early. See [Status](#status) for what actually works today.

---

## Status

**Prototype / active development.** Not production-ready.

The deterministic pixel path is the priority and is largely working. Shader baking and 3D are
early. See [Known limitations](#known-limitations) — this section is deliberately honest so you
don't mistake scaffolding for finished features.

| Area | State |
|---|---|
| Deterministic pixel generation, seeds, palettes | Working |
| Graph drives rendering (renderer, mask, texture, pixelize, seed, radius) | Working |
| Animation timeline, keyframed intensity/radius/spread/direction | Working |
| PNG frame, sprite sheet, and `SpriteFrames` export | Working |
| Pixel editing: paint, erase, selection, onion skin, undo/redo | Working |
| GPU particles → pixel bake | Working |
| Mask node | **Partial** — display-only, no editing controls |
| Texture node | **Partial** — alpha channel only |
| Shader → pixel bake | **Not implemented** |
| 3D authoring | **Demo scene only**, not wired into the graph |

- Automated suite: **75 passed, 0 failed, 0 skipped** across 3 suites.

---

## Requirements

- **Godot 4.7.2 stable** — <https://godotengine.org/download>
- Windows (developed and verified on Windows 10/11)

No addons or external plugins are required. The test harness is vendored in
`tests/harness/`, so the suite runs on a clean clone.

---

## Running

Open the project in Godot 4.7.2 and press **F5**, or:

```powershell
godot --path C:\projects\VFXForge
```

Build a standalone Windows export via **Project → Export** using the `Windows Desktop` preset.

---

## Verifying

Two ways, both currently green.

**Headless (works without the editor UI — use this in CI):**

On a fresh clone, run Godot's import pass once first. Without it, `class_name` declarations
aren't registered yet and the suite reports load errors:

```powershell
godot --headless --path <project> --import
godot --headless --path <project> -s res://tests/run_headless.gd
```

Exit codes: `0` all passed · `1` a test failed · `2` discovery/load error.

**Startup smoke test:**

```powershell
godot --headless --path <project> --quit-after 2
```

`user://logs/godot.log` warnings and shutdown renderer-leak warnings are expected; **script parse
errors are failures**.

**In-editor:** the same suites can also be run from inside the Godot editor via the
`tests/run_headless.gd` entry point.

---

## Project layout

| Path | Contents |
|---|---|
| `core/` | 40 reusable VFX modules (~1,200 lines), all `extends RefCounted`. No editor dependencies. |
| `editor/` | Graph editor widget — drawing, inline node controls, connections, history. |
| `scripts/main.gd` | Main editor shell and UI wiring. |
| `tests/` | `test_*.gd` suites plus the headless runner. |
| `custom_nodes/` | JSON custom-node definitions, discovered at runtime. |
| `palette/` | PNG palette presets discovered by `PaletteLibrary`. |
| `scenes/` | `main.tscn`, SpriteFrames validation, 3D fireball demo. |
| `tests/harness/` | Vendored test framework (assertions, discovery, runner). |

### Architecture rules

- **`core/` must not depend on `editor/` or `scenes/`.** It is a reusable engine.
- Deterministic CPU/pixel output is the product; GPU particles and shaders are preview-only
  until they can be baked deterministically. Export must state which is which.
- The core must not hard-code Haribon dependencies — Haribon style packs are swappable data.

---

## Export formats

| Format | Output |
|---|---|
| PNG frames | One PNG per frame |
| Sprite sheet | Single PNG strip, configurable columns and padding |
| `SpriteFrames` | Godot `.tres` resource with generated textures |

Output goes to the project's `exports/` directory. In a packaged build `res://` is a read-only
pack, so exports fall back to `user://exports` (`%APPDATA%/Godot/app_userdata/Haribon VFXForge/exports`)
rather than silently writing nothing. Export failures are reported in the status bar.

AnimatedTexture2D, GPUParticles2D scene export, shader resource export, and 3D bake are planned
but not implemented.

---

## Known limitations

- **Mask node has no editing controls.** The Inspector renders a read-only label, and the default
  `amount: 1.0` is effectively a no-op on a centred burst.
- **Texture node uses only the source alpha channel**, so an opaque PNG produces no visible
  change. Mask and texture also overwrite rather than compose.
- **No shader → pixel bake.** Shader authoring is preview-only today.
- **3D is isolated.** `scenes/vfx3d_fireball_demo.tscn` works standalone; there are zero 3D
  references in the graph evaluator or pipeline.
- **Preset graphs report `valid: false`.** `PresetLibrary.graph_for()` emits node names
  (`Head`, `Trail`, `Ring`, …) that `GraphEvaluator` does not recognise.
- **Connections don't gate node application yet** — a disconnected node can still take effect.
- `ARCHITECTURE.md`, `ROADMAP.md`, and `KANBAN.md` have drifted from the code and contain
  checkmarks for work that is not actually wired up. Treat the table above as the source of truth.

---

## Roadmap

See [`ROADMAP.md`](ROADMAP.md) for milestones and [`KANBAN.md`](KANBAN.md) for task state. The
active direction is to reach the capability of dedicated VFX authoring tools — deterministic
pixel output first, then a universal bake bridge covering shaders and 3D.

---

## Documentation

| File | Purpose |
|---|---|
| `ARCHITECTURE.md` | Intended layering and contracts |
| `ROADMAP.md` | Vision and milestones |
| `KANBAN.md` | Task board |
| `RELEASE_STATUS.md` | Packaging and release-gate state |
| `ASSISTED_DEBUGGING.md` | Manual runtime verification order |
| `PixelVFXForge_Project_Plan.md` | Original specification |

---

## License

[MIT](LICENSE) © 2026 hardc0l2e