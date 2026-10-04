@tool
extends "res://tests/harness/test_suite.gd"

const ImpactGenerator = preload("res://core/impact_generator.gd")
const ExportPlan = preload("res://core/export_plan.gd")
const PaletteLoader = preload("res://core/palette_loader.gd")
const ProjectCodec = preload("res://core/project_codec.gd")
const ImageExporter = preload("res://core/image_exporter.gd")
const RendererContract = preload("res://core/renderer_contract.gd")
const CpuParticleBackend = preload("res://core/cpu_particle_backend.gd")
const PresetLibrary = preload("res://core/preset_library.gd")
const PresetPreviewGenerator = preload("res://core/preset_preview_generator.gd")
const SpriteFramesValidation = preload("res://scripts/sprite_frames_validation.gd")
const PaletteLibrary = preload("res://core/palette_library.gd")
const StylePackLibrary = preload("res://core/style_pack_library.gd")
const PixelTools = preload("res://core/pixel_tools.gd")
const PaletteSet = preload("res://core/palette_set.gd")
const ProjectMigration = preload("res://core/project_migration.gd")
const PreferencesStore = preload("res://core/preferences_store.gd")
const RecoveryManager = preload("res://core/recovery_manager.gd")
const PixelCompositor = preload("res://core/compositor.gd")
const SpriteFramesExporter = preload("res://core/sprite_frames_exporter.gd")
const PixelHistory = preload("res://core/pixel_history.gd")
const ProjectManager = preload("res://core/project_manager.gd")
const PixelSelection = preload("res://core/pixel_selection.gd")
const OnionSkin = preload("res://core/onion_skin.gd")
const ParameterAnimation = preload("res://core/parameter_animation.gd")
const VFXBakeProfile = preload("res://core/vfx_bake_profile.gd")
const FrameBaker = preload("res://core/frame_baker.gd")
const FrameCompositor = preload("res://core/frame_compositor.gd")
const SubViewportBaker = preload("res://core/subviewport_baker.gd")
const MainShell = preload("res://scripts/main.gd")

func test_writable_dir_creates_and_accepts_existing_directory() -> void:
	var dir := "user://writable_probe"
	DirAccess.remove_absolute(dir)
	assert_true(MainShell._writable_dir(dir))
	assert_true(DirAccess.dir_exists_absolute(dir))
	assert_true(MainShell._writable_dir(dir))
	assert_false(DirAccess.dir_exists_absolute(dir.path_join(".write_probe")))
	DirAccess.remove_absolute(dir)

func suite_name() -> String:
	return "asset_pipeline"

func test_export_formats_have_stable_plans() -> void:
	var png := ExportPlan.for_format("PNG")
	var sheet := ExportPlan.for_format("SpriteSheet")
	var sprite_frames := ExportPlan.for_format("SpriteFrames")
	assert_eq(png.kind, "png_frames")
	assert_eq(sheet.kind, "sprite_sheet")
	assert_eq(sprite_frames.kind, "godot_sprite_frames")
	assert_true(sprite_frames.requires_textures)
	assert_true(ExportPlan.is_supported("PNG"))
	assert_false(ExportPlan.is_supported("Unknown"))

func test_impact_generation_is_deterministic() -> void:
	var palette: Array[Color] = [Color.WHITE, Color("#78ffd9")]
	var first := ImpactGenerator.generate(Vector2i(8, 8), 99, 4, 1.0, palette, 80, 1.0, 0.0)
	var second := ImpactGenerator.generate(Vector2i(8, 8), 99, 4, 1.0, palette, 80, 1.0, 0.0)
	assert_eq(first.pixels, second.pixels)

func test_different_seed_changes_generated_pixels() -> void:
	var palette: Array[Color] = [Color.WHITE, Color("#78ffd9")]
	var first := ImpactGenerator.generate(Vector2i(8, 8), 99, 4, 1.0, palette, 80, 1.0, 0.0)
	var second := ImpactGenerator.generate(Vector2i(8, 8), 100, 4, 1.0, palette, 80, 1.0, 0.0)
	assert_ne(first.pixels, second.pixels)

func test_png_palette_loads_unique_colors() -> void:
	var palette := PaletteLoader.load_png("res://raw/sample_palette.png")
	assert_eq(palette.size(), 4)
	assert_true(palette[0].a > 0.0)

func test_palette_imported_resource_matches_source_file() -> void:
	var path := "res://raw/sample_palette.png"
	var texture := load(path) as Texture2D
	assert_true(texture != null)
	var resource_image := texture.get_image()
	assert_true(resource_image != null)
	var from_resource := PaletteLoader.colors_from_image(resource_image)
	var from_file := PaletteLoader.load_png(path)
	assert_eq(from_resource.size(), 4)
	assert_eq(from_resource.size(), from_file.size())
	for index in from_file.size():
		assert_true(from_resource[index].is_equal_approx(from_file[index]))

func test_palette_missing_source_returns_empty() -> void:
	assert_true(PaletteLoader.load_png("res://palette/does_not_exist.png").is_empty())

func test_palette_png_round_trip_preserves_color_count() -> void:
	var path := "user://test_palette_roundtrip.png"
	var colors: Array[Color] = [Color.RED, Color("#78ffd9"), Color.BLUE]
	assert_true(PaletteLoader.save_png(path, colors))
	var restored := PaletteLoader.load_png(path)
	assert_eq(restored.size(), 3)
	assert_true(restored[1].is_equal_approx(colors[1]))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func test_project_codec_round_trips_filesystem_data() -> void:
	var path := "user://vfxforge_codec_test.vfxproj"
	var project := {"version": 1, "canvas_size": [32, 32], "frames": [["ffffff"]], "graph": {"connections": []}}
	assert_true(ProjectCodec.write(path, project))
	var restored := ProjectCodec.read(path)
	assert_eq(restored.get("version"), 1)
	var restored_size = restored.get("canvas_size", [])
	assert_eq(int(restored_size[0]), 32)
	assert_eq(int(restored_size[1]), 32)
	assert_eq(restored.get("frames"), [["ffffff"]])
	assert_true(restored.get("graph", {}).has("connections"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func test_project_codec_rejects_invalid_json() -> void:
	assert_true(ProjectCodec.decode("not json").is_empty())

func test_canvas_export_preserves_integer_pixel_scale() -> void:
	var canvas := PixelCanvas.new(Vector2i(2, 1))
	canvas.set_pixel(Vector2i(0, 0), Color.RED)
	canvas.set_pixel(Vector2i(1, 0), Color.BLUE)
	var image := ImageExporter.canvas_to_image(canvas, 4)
	assert_eq(image.get_size(), Vector2i(8, 4))
	assert_eq(image.get_pixel(1, 1), Color.RED)
	assert_eq(image.get_pixel(6, 2), Color.BLUE)

func test_sprite_sheet_export_has_expected_dimensions() -> void:
	var frames: Array[PixelCanvas] = []
	for index in 3:
		var canvas := PixelCanvas.new(Vector2i(2, 2))
		canvas.set_pixel(Vector2i(index % 2, 0), Color.WHITE)
		frames.append(canvas)
	var sheet := ImageExporter.make_sprite_sheet(frames, 2, 4)
	assert_eq(sheet.get_size(), Vector2i(16, 16))
	var padded := ImageExporter.make_sprite_sheet(frames, 2, 4, 2)
	assert_eq(padded.get_size(), Vector2i(24, 24))

func test_sprite_frames_exporter_writes_all_frame_resources() -> void:
	var resource := SpriteFramesExporter.build_resource(3)
	assert_true(resource.begins_with("[gd_resource type=\"SpriteFrames\""))
	assert_eq(resource.count("type=\"Texture2D\""), 3)
	assert_true(resource.contains("frame_01.png"))
	assert_true(resource.contains("frame_02.png"))
	assert_true(resource.contains("frame_03.png"))
	assert_true(resource.contains("speed\": 24.000"))
	assert_true(SpriteFramesExporter.build_resource(3, "res://exports/frames", 30.0).contains("speed\": 30.000"))

func test_renderer_contract_marks_cpu_particles_bakeable() -> void:
	var contract := RendererContract.describe(RendererContract.CPU_PARTICLES)
	assert_true(contract.deterministic)
	assert_true(contract.bake)

func test_cpu_particles_are_seed_deterministic() -> void:
	var first := CpuParticleBackend.emit(7, 4, 1.0, 10.0)
	var second := CpuParticleBackend.emit(7, 4, 1.0, 10.0)
	assert_eq(first, second)

func test_cpu_particles_bake_seeded_pixel_frames_deterministically() -> void:
	var first := CpuParticleBackend.bake_frames(Vector2i(16, 16), 7, 8, 3, 1.0, 2.0, 0.1, Color("#78ffd9"))
	var second := CpuParticleBackend.bake_frames(Vector2i(16, 16), 7, 8, 3, 1.0, 2.0, 0.1, Color("#78ffd9"))
	assert_eq(first.size(), 3)
	assert_eq(first[0].pixels, second[0].pixels)
	assert_eq(first[1].pixels, second[1].pixels)

func test_builtin_presets_include_hybrid_preview() -> void:
	var preset := PresetLibrary.find("Glow Impact")
	assert_eq(preset.get("renderer"), "Hybrid")

func test_preset_library_contains_core_vfx_generators() -> void:
	for name in ["Slash", "Explosion", "Projectile", "Fire", "Lightning", "Smoke", "Magic"]:
		var preset := PresetLibrary.find(name)
		assert_false(preset.is_empty())
		assert_true(preset.has("parameters"))

func test_vfx_presets_explain_projectile_and_aoe_recipes() -> void:
	var projectile := PresetLibrary.find("Projectile")
	var aoe := PresetLibrary.find("AOE Attack")
	assert_eq(projectile.get("recipe"), ["Head", "Trail", "Output"])
	assert_eq(aoe.get("recipe"), ["Core", "Ring", "Sparks", "Output"])

func test_preset_graph_recipe_has_connected_stages() -> void:
	var graph := PresetLibrary.graph_for("Projectile")
	assert_eq(graph.get("nodes", []).size(), 4)
	assert_eq(graph.get("nodes", [])[1].get("name"), "Head")
	assert_eq(graph.get("nodes", [])[2].get("name"), "Trail")
	assert_eq(graph.get("connections", []).size(), 3)

func test_preset_preview_generator_produces_visible_frames() -> void:
	var palette: Array[Color] = [Color.WHITE, Color("#78ffd9"), Color("#ff9b6a")]
	for preset_name in ["Projectile", "Spark Burst", "AOE Attack"]:
		var frames := PresetPreviewGenerator.generate_frames(Vector2i(32, 32), 42, 4, palette, preset_name)
		assert_eq(frames.size(), 4)
		assert_true(frames[0].pixels.count(Color.TRANSPARENT) < frames[0].pixels.size())

func test_all_builtin_presets_produce_visible_preview_frames() -> void:
	var palette: Array[Color] = [Color.WHITE, Color("#78ffd9"), Color("#ff9b6a")]
	for preset in PresetLibrary.builtins():
		var frames := PresetPreviewGenerator.generate_frames(Vector2i(32, 32), 42, 2, palette, String(preset.name))
		assert_eq(frames.size(), 2)
		assert_true(frames[0].pixels.count(Color.TRANSPARENT) < frames[0].pixels.size())

func test_production_directional_presets_generate_distinct_visible_frames() -> void:
	var palette: Array[Color] = [Color.WHITE, Color("#78ffd9"), Color("#ff9b6a")]
	var fireball := PresetPreviewGenerator.generate_frames(Vector2i(32, 32), 42, 4, palette, "Fireball Projectile")
	var sideways := PresetPreviewGenerator.generate_frames(Vector2i(32, 32), 42, 4, palette, "Lightning Sideways")
	var downward := PresetPreviewGenerator.generate_frames(Vector2i(32, 32), 42, 4, palette, "Lightning Downward")
	assert_true(fireball[1].pixels.count(Color.TRANSPARENT) < fireball[1].pixels.size())
	assert_true(sideways[1].pixels.count(Color.TRANSPARENT) < sideways[1].pixels.size())
	assert_true(downward[1].pixels.count(Color.TRANSPARENT) < downward[1].pixels.size())
	assert_ne(sideways[1].pixels, downward[1].pixels)

func test_aoe_preview_keeps_ring_inside_canvas_edges() -> void:
	var palette: Array[Color] = [Color.WHITE, Color("#78ffd9"), Color("#ff9b6a")]
	var frames := PresetPreviewGenerator.generate_frames(Vector2i(32, 32), 42, 4, palette, "AOE Attack")
	var last := frames[frames.size() - 1]
	for x in 32:
		assert_eq(last.get_pixel(Vector2i(x, 0)), Color.TRANSPARENT)
		assert_eq(last.get_pixel(Vector2i(x, 31)), Color.TRANSPARENT)
	for y in 32:
		assert_eq(last.get_pixel(Vector2i(0, y)), Color.TRANSPARENT)
		assert_eq(last.get_pixel(Vector2i(31, y)), Color.TRANSPARENT)

func test_aoe_radius_parameter_changes_ring_size() -> void:
	var palette: Array[Color] = [Color.WHITE, Color("#78ffd9"), Color("#ff9b6a")]
	var small := PresetPreviewGenerator.generate_frames(Vector2i(32, 32), 42, 4, palette, "AOE Attack", 4.0)
	var large := PresetPreviewGenerator.generate_frames(Vector2i(32, 32), 42, 4, palette, "AOE Attack", 14.0)
	assert_ne(small[3].pixels, large[3].pixels)

func test_vfx_bake_profile_round_trips_3d_capture_settings() -> void:
	var profile := VFXBakeProfile.new()
	profile.resolution = Vector2i(512, 256)
	profile.frame_count = 48
	profile.fps = 30.0
	profile.orthographic_scale = 6.0
	profile.supersample = 4
	var restored = VFXBakeProfile.from_dictionary(profile.to_dictionary())
	assert_eq(restored.resolution, Vector2i(512, 256))
	assert_eq(restored.frame_count, 48)
	assert_eq(restored.fps, 30.0)
	assert_eq(restored.supersample, 4)

func test_frame_baker_resizes_nearest_without_blending() -> void:
	var source := PixelCanvas.new(Vector2i(2, 2))
	source.set_pixel(Vector2i(0, 0), Color.RED)
	source.set_pixel(Vector2i(1, 1), Color.BLUE)
	var result := FrameBaker.resize_nearest(source, Vector2i(4, 4))
	assert_eq(result.size, Vector2i(4, 4))
	assert_eq(result.get_pixel(Vector2i(0, 0)), Color.RED)
	assert_eq(result.get_pixel(Vector2i(3, 3)), Color.BLUE)
	assert_eq(result.get_pixel(Vector2i(1, 2)), Color.TRANSPARENT)

func test_frame_baker_radial_mask_removes_outer_pixels() -> void:
	var source := PixelCanvas.new(Vector2i(8, 8))
	for y in 8:
		for x in 8:
			source.set_pixel(Vector2i(x, y), Color.WHITE)
	var result := FrameBaker.apply_radial_mask(source, 0.5)
	assert_eq(result.get_pixel(Vector2i(0, 0)), Color.TRANSPARENT)
	assert_eq(result.get_pixel(Vector2i(4, 4)), Color.WHITE)

func test_frame_baker_texture_alpha_masks_frame() -> void:
	var source := PixelCanvas.new(Vector2i(2, 2))
	for y in 2:
		for x in 2:
			source.set_pixel(Vector2i(x, y), Color.WHITE)
	var texture := Image.create(2, 2, false, Image.FORMAT_RGBA8)
	texture.fill(Color.WHITE)
	texture.set_pixel(0, 0, Color(1, 1, 1, 0))
	var result := FrameBaker.apply_texture_alpha(source, texture)
	assert_eq(result.get_pixel(Vector2i(0, 0)), Color(1, 1, 1, 0))
	assert_eq(result.get_pixel(Vector2i(1, 1)), Color.WHITE)

func test_frame_compositor_adds_visible_glow_without_erasing_core() -> void:
	var source := PixelCanvas.new(Vector2i(7, 7))
	source.set_pixel(Vector2i(3, 3), Color(0.2, 1.0, 0.8, 1.0))
	var result := FrameCompositor.additive_glow(source, 2, 0.35)
	assert_true(result.get_pixel(Vector2i(3, 3)).a > 0.0)
	assert_true(result.get_pixel(Vector2i(2, 3)).a > 0.0)

func test_subviewport_baker_converts_captured_images_to_nearest_pixel_frames() -> void:
	var image := Image.create(2, 2, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	image.set_pixel(0, 0, Color.RED)
	var frames := SubViewportBaker.images_to_pixel_canvases([image], Vector2i(4, 4))
	assert_eq(frames.size(), 1)
	assert_eq(frames[0].get_pixel(Vector2i(0, 0)), Color.RED)
	assert_eq(frames[0].get_pixel(Vector2i(3, 3)), Color.TRANSPARENT)

func test_preset_export_names_are_stable() -> void:
	assert_eq(PresetLibrary.file_slug("Projectile"), "projectile")
	assert_eq(PresetLibrary.file_slug("Spark Burst"), "spark_burst")
	assert_eq(PresetLibrary.file_slug("AOE Attack"), "aoe_attack")

func test_sprite_frames_validation_discovers_preset_exports() -> void:
	var fixture := "user://sprite_frames_fixture"
	DirAccess.make_dir_recursive_absolute(fixture)
	for name in ["beta_sprite_frames.tres", "alpha_sprite_frames.tres", "notes.txt"]:
		var file := FileAccess.open(fixture.path_join(name), FileAccess.WRITE)
		file.store_string("fixture")
		file.close()
	assert_eq(SpriteFramesValidation.find_sprite_frames_path(fixture), fixture.path_join("alpha_sprite_frames.tres"))
	assert_eq(SpriteFramesValidation.find_sprite_frames_path("user://no_such_export_dir"), "")
	for name in ["alpha_sprite_frames.tres", "beta_sprite_frames.tres", "notes.txt"]:
		DirAccess.remove_absolute(fixture.path_join(name))
	DirAccess.remove_absolute(fixture)

func test_palette_browser_discovers_png_presets() -> void:
	var names := PaletteLibrary.scan_png_names("res://palette")
	assert_true(names.has("sample_palette"))

func test_haribon_style_packs_have_named_color_sets() -> void:
	assert_eq(StylePackLibrary.builtins().size(), 3)
	assert_eq(StylePackLibrary.find("Haribon Ember").size(), 4)
	assert_eq(StylePackLibrary.find("Haribon Frost")[1].to_html(false), "78ffd9")
	assert_true(StylePackLibrary.find("Missing Pack").is_empty())

func test_pixel_tools_draw_and_fill() -> void:
	var canvas := PixelCanvas.new(Vector2i(5, 5))
	PixelTools.line(canvas, Vector2i(0, 0), Vector2i(4, 4), Color.RED)
	PixelTools.rectangle(canvas, Rect2i(1, 1, 3, 3), Color.BLUE, false)
	PixelTools.flood_fill(canvas, Vector2i(4, 0), Color.GREEN)
	assert_eq(canvas.get_pixel(Vector2i(0, 0)), Color.RED)
	assert_eq(canvas.get_pixel(Vector2i(2, 1)), Color.BLUE)
	assert_eq(canvas.get_pixel(Vector2i(4, 0)), Color.GREEN)

func test_pixel_history_restores_edits_and_supports_redo() -> void:
	var history := PixelHistory.new()
	var original := PixelCanvas.new(Vector2i(2, 1))
	var edited := PixelCanvas.new(Vector2i(2, 1))
	edited.set_pixel(Vector2i.ZERO, Color.RED)
	history.record(original)
	var restored := history.undo(edited)
	assert_eq(restored.get_pixel(Vector2i.ZERO), Color.TRANSPARENT)
	var redone := history.redo(restored)
	assert_eq(redone.get_pixel(Vector2i.ZERO), Color.RED)

func test_pixel_selection_moves_a_rectangular_pixel_region() -> void:
	var canvas := PixelCanvas.new(Vector2i(4, 2))
	canvas.set_pixel(Vector2i(0, 0), Color.RED)
	canvas.set_pixel(Vector2i(1, 0), Color.BLUE)
	var selection := PixelSelection.new()
	selection.capture(canvas, Rect2i(0, 0, 2, 1))
	selection.move(canvas, Vector2i(2, 1))
	assert_eq(canvas.get_pixel(Vector2i(0, 0)), Color.TRANSPARENT)
	assert_eq(canvas.get_pixel(Vector2i(2, 1)), Color.RED)
	assert_eq(canvas.get_pixel(Vector2i(3, 1)), Color.BLUE)

func test_onion_skin_clamps_overlay_opacity_and_keeps_adjacent_frames() -> void:
	var previous := PixelCanvas.new(Vector2i(1, 1))
	var next := PixelCanvas.new(Vector2i(1, 1))
	var overlay := OnionSkin.overlay(previous, next, -1.0, 2.0)
	assert_eq(overlay.get("previous"), previous)
	assert_eq(overlay.get("next"), next)
	assert_eq(overlay.get("previous_opacity"), 0.0)
	assert_eq(overlay.get("next_opacity"), 1.0)

func test_parameter_animation_supports_multiple_named_tracks() -> void:
	var animation := ParameterAnimation.new()
	animation.add_key("radius", 0.0, 4.0)
	animation.add_key("radius", 1.0, 12.0)
	animation.add_key("direction", 0.0, -1.0)
	assert_eq(animation.sample("radius", 0.5, 0.0), 8.0)
	assert_eq(animation.sample("direction", 0.5, 0.0), -1.0)

func test_palette_set_serializes_and_deduplicates_colors() -> void:
	var palette := PaletteSet.new("Test", [Color.RED])
	palette.add_color(Color.RED)
	palette.add_color(Color.BLUE)
	var restored = PaletteSet.deserialize(palette.serialize())
	assert_eq(restored.name, "Test")
	assert_eq(restored.colors.size(), 2)

func test_palette_set_can_edit_current_colors_without_duplicates() -> void:
	var palette := PaletteSet.new("Editable", [Color.RED])
	palette.add_color(Color.RED)
	palette.add_color(Color.GREEN)
	assert_eq(palette.colors.size(), 2)
	palette.remove_color(0)
	assert_eq(palette.colors, [Color.GREEN])

func test_project_migration_adds_renderer_to_legacy_data() -> void:
	var migrated := ProjectMigration.migrate({"version": 1, "canvas_size": [32, 32], "frames": []})
	assert_eq(migrated.get("version"), ProjectMigration.CURRENT_VERSION)
	assert_eq(migrated.get("renderer"), "Pixel CPU")
	assert_true(ProjectMigration.validate(migrated).is_empty())

func test_project_validation_reports_malformed_dimensions_and_fps() -> void:
	var errors := ProjectMigration.validate({"canvas_size": [0, 32], "frames": {}, "fps": 0})
	assert_eq(errors.size(), 3)
	assert_true(errors[0].contains("frames"))
	assert_true(errors[1].contains("canvas_size"))
	assert_true(errors[2].contains("fps"))

func test_preferences_store_applies_defaults() -> void:
	var values := PreferencesStore.normalize({"show_grid": false})
	assert_false(values.show_grid)
	assert_eq(values.ui_scale, 1.0)

func test_recovery_manager_uses_user_recovery_path() -> void:
	assert_true(RecoveryManager.recovery_path().contains("haribon_vfxforge_recovery.vfxproj"))

func test_project_manager_deduplicates_and_prioritizes_recent_projects() -> void:
	var recent := ProjectManager.add_recent(["res://old.vfxproj", "res://other.vfxproj"], "res://other.vfxproj")
	assert_eq(recent[0], "res://other.vfxproj")
	assert_eq(recent.size(), 2)

func test_compositor_alpha_over_blends_pixel_frames() -> void:
	var base := PixelCanvas.new(Vector2i(1, 1))
	var overlay := PixelCanvas.new(Vector2i(1, 1))
	base.set_pixel(Vector2i.ZERO, Color(1, 0, 0, 1))
	overlay.set_pixel(Vector2i.ZERO, Color(0, 0, 1, 0.5))
	var result := PixelCompositor.blend_frames(base, overlay)
	var color := result.get_pixel(Vector2i.ZERO)
	assert_true(is_equal_approx(color.a, 1.0))
	assert_true(color.r > 0.0 and color.b > 0.0)
