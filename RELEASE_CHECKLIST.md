# Haribon VFXForge Release Checklist

## Runtime

- [ ] Launches on a clean Windows machine.
- [ ] Main editor opens at 1280×720 and adapts to larger desktop windows.
- [ ] File save/load and autosave recovery work.
- [ ] Graph zoom, pan, snapping, reconnect, reroute, undo, and redo work.

## Authoring

- [ ] Pixel tools pass manual checks.
- [ ] Palette PNG loading and palette-set editing work.
- [ ] CPU, GPU, shader, and hybrid previews show correct capability warnings.
- [ ] Timeline keyframes update preview parameters.
- [ ] Vector preview and pixel compositing remain aligned.

## Export

- [ ] PNG frame export verified.
- [ ] Sprite-sheet export verified.
- [ ] SpriteFrames playback verified in the validation scene.
- [ ] Preview-only renderer warnings appear before export.

## Verification

- [x] Godot headless startup passes without script errors.
- [x] Godot AI/local headless test suite passes.
- [ ] Clean export build completes using `export_presets.cfg` (requires the
  matching Godot 4.7.2 Windows export templates).
- [x] Known warnings are documented and reviewed.
