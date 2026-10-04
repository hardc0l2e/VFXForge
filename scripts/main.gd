extends Control

const ImpactGenerator = preload("res://core/impact_generator.gd")
const PresetPreviewGenerator = preload("res://core/preset_preview_generator.gd")
const GraphEditor = preload("res://editor/graph_editor.gd")
const GraphEvaluator = preload("res://core/graph_evaluator.gd")
const ExportPlan = preload("res://core/export_plan.gd")
const PaletteLoader = preload("res://core/palette_loader.gd")
const PaletteLibrary = preload("res://core/palette_library.gd")
const StylePackLibrary = preload("res://core/style_pack_library.gd")
const ProjectCodec = preload("res://core/project_codec.gd")
const ImageExporter = preload("res://core/image_exporter.gd")
const RendererContract = preload("res://core/renderer_contract.gd")
const PresetLibrary = preload("res://core/preset_library.gd")
const CpuParticlePreview = preload("res://editor/cpu_particle_preview.gd")
const ProjectMigration = preload("res://core/project_migration.gd")
const PreferencesStore = preload("res://core/preferences_store.gd")
const RecoveryManager = preload("res://core/recovery_manager.gd")
const ParameterAnimation = preload("res://core/parameter_animation.gd")
const VectorPreview = preload("res://editor/vector_preview.gd")
const SpriteFramesExporter = preload("res://core/sprite_frames_exporter.gd")
const CustomNodeLibrary = preload("res://core/custom_node_library.gd")
const ProjectManager = preload("res://core/project_manager.gd")
const PixelHistory = preload("res://core/pixel_history.gd")
const OnionSkin = preload("res://core/onion_skin.gd")
const PlaybackClock = preload("res://core/playback_clock.gd")
const FrameBaker = preload("res://core/frame_baker.gd")
const FrameCompositor = preload("res://core/frame_compositor.gd")
const VFXPipeline = preload("res://core/vfx_pipeline.gd")
const GpuParticleBakeService = preload("res://core/gpu_particle_bake_service.gd")
const SubViewportBaker = preload("res://core/subviewport_baker.gd")

const CANVAS_SIZE := Vector2i(32, 32)
const CANVAS_PIXEL_SIZE := 12
const ACCENT_COLOR := Color("#78ffd9")
const PANEL_COLOR := Color("#20242b")
const TEXT_COLOR := Color("#d7e3e0")

var pixel_canvas := PixelCanvas.new(CANVAS_SIZE)
var pixelize_resolution := CANVAS_SIZE
var pixelize_enabled := true
var mask_mode := ""
var mask_amount := 1.0
var texture_path := ""
var canvas_view: Control
var status_label: Label
var frames: Array[PixelCanvas] = []
var current_frame := 0
var is_playing := false
var playback_accumulator := 0.0
var play_button: Button
var frame_slider: HSlider
var timeline_hint: Label
var seed_input: LineEdit
var palette_grid: GridContainer
var palette_selector: OptionButton
var palette_status_label: Label
var color_picker_control: ColorPickerButton
var export_columns := 12
var export_padding := 0
var gpu_particles: GPUParticles2D
var shader_preview: ColorRect
var shader_material: ShaderMaterial
var cpu_particle_preview: CpuParticlePreview
var vector_preview: VectorPreview
var graph_editor: GraphEditor
var selected_node_label: Label
var node_parameters_container: VBoxContainer
var pixel_history := PixelHistory.new()
var file_dialog: FileDialog
var palette_file_dialog: FileDialog
var texture_file_dialog: FileDialog
var palette_save_dialog: FileDialog
var export_dialog: ConfirmationDialog
var export_format_option: OptionButton
var export_columns_spin: SpinBox
var export_padding_spin: SpinBox
var recent_projects: Array[String] = []
const RECENT_PROJECTS_PATH := "user://haribon_vfxforge_recent_projects.json"
var file_dialog_mode := FileDialog.FILE_MODE_OPEN_FILE
var radius := 10
var intensity := 1.0
var seed_value := 391822
var global_seed_value := 391822
var particle_count := 80
var spread := 1.0
var direction := 0.0
var frame_count := 12
var frames_per_second := 24.0
var paint_color := Color("#fff4c2")
var renderer_mode := RendererContract.PIXEL_CPU
var renderer_selector: OptionButton
var preset_selector: OptionButton
var autosave_elapsed := 0.0
var preferences := PreferencesStore.DEFAULTS.duplicate(true)
var parameter_animation := ParameterAnimation.new()
var onion_skin_enabled := false
var pixel_selection := PixelSelection.new()

var fire_palette: Array[Color] = [
	Color("#fff4c2"),
	Color("#ffcf5c"),
	Color("#f2764b"),
	Color("#a83d56"),
]
var ice_palette: Array[Color] = [
	Color("#e5fff9"),
	Color("#78ffd9"),
	Color("#43b9d1"),
	Color("#31558c"),
]
var active_palette: Array[Color]
var active_palette_name := "Fire"
var project_name := "Untitled Effect"
var active_preset_name := "Impact"
var export_settings := {"format": "SpriteFrames", "columns": 12, "pixel_scale": CANVAS_PIXEL_SIZE}
var using_ice_palette := false
var gpu_bake_service := GpuParticleBakeService.new()

func _ready() -> void:
	# Explicitly enforce a normal desktop window for exported builds. This also
	# overrides stale per-user fullscreen/borderless settings from older builds.
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
	DisplayServer.window_set_size(Vector2i(1600, 900))
	call_deferred("_enforce_windowed_mode")
	preferences = PreferencesStore.read("user://haribon_vfxforge_preferences.json")
	renderer_mode = String(preferences.get("last_renderer", renderer_mode))
	active_palette = fire_palette.duplicate()
	_regenerate_frames()
	_build_interface()

func _build_interface() -> void:
	var background := ColorRect.new()
	background.color = Color("#111519")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 0)
	var compact_theme := _ui_theme()
	root.theme = compact_theme
	add_child(root)

	var menu_bar := MenuBar.new()
	menu_bar.add_theme_color_override("font_color", TEXT_COLOR)
	menu_bar.add_theme_color_override("font_hover_color", ACCENT_COLOR)
	menu_bar.custom_minimum_size.y = 32
	var file_menu := PopupMenu.new()
	file_menu.name = "File"
	file_menu.add_item("New VFX", 1)
	file_menu.add_item("Save Project", 2)
	file_menu.add_item("Load Project", 4)
	var export_menu := PopupMenu.new()
	export_menu.name = "Exports"
	export_menu.add_item("All Exports", 20)
	export_menu.add_separator()
	export_menu.add_item("Export Graph Output...", 3)
	export_menu.add_item("PNG Frames", 5)
	export_menu.add_item("Sprite Sheet: Horizontal", 6)
	export_menu.add_item("Sprite Sheet: Vertical", 7)
	export_menu.add_item("Sprite Sheet: Grid", 8)
	export_menu.add_item("Godot SpriteFrames", 9)
	export_menu.id_pressed.connect(_on_file_menu_pressed)
	file_menu.add_submenu_node_item("Exports", export_menu)
	file_menu.add_item("Recover Autosave", 10)
	file_menu.add_separator()
	file_menu.add_item("Undo Pixel Edit", 11)
	file_menu.add_item("Redo Pixel Edit", 12)
	file_menu.add_separator()
	file_menu.add_item("Exit", 13)
	recent_projects = ProjectManager.read(RECENT_PROJECTS_PATH)
	if not recent_projects.is_empty():
		file_menu.add_separator()
		for index in recent_projects.size():
			file_menu.add_item("Open Recent: " + recent_projects[index].get_file(), 100 + index)
	file_menu.id_pressed.connect(_on_file_menu_pressed)
	menu_bar.add_child(file_menu)
	root.add_child(menu_bar)
	var brand := Label.new()
	brand.text = "HARIBON VFXFORGE"
	brand.add_theme_color_override("font_color", ACCENT_COLOR)
	brand.custom_minimum_size.y = 24
	root.add_child(brand)

	var workspace := HSplitContainer.new()
	workspace.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(workspace)

	var node_library := PanelContainer.new()
	node_library.add_theme_stylebox_override("panel", _panel_style())
	var node_library_theme := _ui_theme()
	node_library.theme = node_library_theme
	var node_library_column := VBoxContainer.new()
	node_library_column.add_theme_constant_override("separation", 3)
	node_library.add_child(node_library_column)
	var node_library_title := Label.new()
	node_library_title.text = "NODE LIBRARY"
	node_library_column.add_child(node_library_title)
	for registered_name in ["Scalar Math", "Vector Math", "Noise Field", "GPU Particles", "CPU Particles", "Shader", "Mask", "Texture"]:
		var add_button := Button.new()
		add_button.text = "+ " + registered_name
		add_button.add_theme_font_size_override("font_size", 12)
		add_button.custom_minimum_size.y = 28
		add_button.pressed.connect(func() -> void:
			if graph_editor != null:
				graph_editor.add_registered_node(registered_name)
		)
		node_library_column.add_child(add_button)
	var custom_nodes := CustomNodeLibrary.load_directory("res://custom_nodes")
	for custom_definition in custom_nodes.nodes:
		var custom_button := Button.new()
		custom_button.text = "+ " + String(custom_definition.get("name", "Custom Node"))
		custom_button.add_theme_font_size_override("font_size", 12)
		custom_button.custom_minimum_size.y = 28
		custom_button.tooltip_text = "Custom | %s" % String(custom_definition.get("category", "Custom"))
		custom_button.pressed.connect(func() -> void:
			if graph_editor != null:
				graph_editor.add_custom_node(custom_definition)
		)
		node_library_column.add_child(custom_button)
	node_library.custom_minimum_size.x = 160
	workspace.add_child(node_library)

	var right_split := HSplitContainer.new()
	right_split.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	workspace.add_child(right_split)
	var center := VSplitContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_split.add_child(center)

	var graph_panel := PanelContainer.new()
	graph_panel.add_theme_stylebox_override("panel", _panel_style())
	graph_panel.custom_minimum_size.y = 180
	graph_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	graph_panel.size_flags_stretch_ratio = 1.0
	graph_editor = GraphEditor.new()
	graph_editor.custom_minimum_size.y = 170
	graph_editor.graph_changed.connect(_on_graph_changed)
	graph_editor.node_selected.connect(_on_graph_node_selected)
	graph_editor.graph_notice.connect(func(message: String) -> void:
		if status_label != null:
			status_label.text = message
	)
	graph_editor.palette_load_requested.connect(func() -> void:
		palette_file_dialog.popup_centered_ratio(0.7)
	)
	graph_panel.add_child(graph_editor)
	center.add_child(graph_panel)

	var preview_section := VBoxContainer.new()
	preview_section.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview_section.size_flags_stretch_ratio = 1.0
	center.add_child(preview_section)
	var preview_title := Label.new()
	preview_title.text = "LIVE PREVIEW"
	preview_title.add_theme_color_override("font_color", ACCENT_COLOR)
	preview_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_title.custom_minimum_size.y = 28
	preview_section.add_child(preview_title)

	canvas_view = PixelCanvasView.new()
	canvas_view.canvas = pixel_canvas
	canvas_view.pixel_size = CANVAS_PIXEL_SIZE
	canvas_view.clip_contents = true
	canvas_view.zoom = 1.0
	canvas_view.pixel_pressed.connect(_on_pixel_pressed)
	canvas_view.selection_created.connect(func(area: Rect2i) -> void:
		pixel_selection.capture(pixel_canvas, area)
		canvas_view.selection_bounds = area
		status_label.text = "Selected region  |  %d × %d" % [area.size.x, area.size.y]
	)
	canvas_view.selection_moved.connect(func(destination: Vector2i) -> void:
		if pixel_selection.is_empty():
			return
		pixel_history.record(pixel_canvas)
		pixel_selection.move(pixel_canvas, destination)
		frames[current_frame] = pixel_canvas
		canvas_view.canvas = pixel_canvas
		canvas_view.selection_bounds = pixel_selection.bounds
		canvas_view.queue_redraw()
		status_label.text = "Selection moved  |  %d × %d" % [pixel_selection.bounds.size.x, pixel_selection.bounds.size.y]
	)
	canvas_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview_section.add_child(canvas_view)
	_setup_gpu_preview()

	var timeline := _build_timeline()
	timeline.custom_minimum_size.y = 96
	timeline.size_flags_vertical = Control.SIZE_SHRINK_END
	preview_section.add_child(timeline)

	var right_column := _build_right_column()
	right_split.add_child(right_column)

	status_label = Label.new()
	status_label.text = "Foundation ready  |  Pixel canvas: 32 × 32"
	status_label.custom_minimum_size.y = 28
	root.add_child(status_label)

	file_dialog = FileDialog.new()
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.filters = PackedStringArray(["*.vfxproj ; Haribon VFXForge Project"])
	file_dialog.file_selected.connect(_on_project_file_selected)
	add_child(file_dialog)

	palette_file_dialog = FileDialog.new()
	palette_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	palette_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	palette_file_dialog.title = "Load PNG Palette"
	palette_file_dialog.filters = PackedStringArray(["*.png ; PNG Palette"])
	palette_file_dialog.file_selected.connect(_on_palette_file_selected)
	add_child(palette_file_dialog)
	texture_file_dialog = FileDialog.new()
	texture_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	texture_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	texture_file_dialog.title = "Load Texture PNG"
	texture_file_dialog.filters = PackedStringArray(["*.png ; Texture PNG"])
	texture_file_dialog.file_selected.connect(_on_texture_file_selected)
	add_child(texture_file_dialog)
	palette_save_dialog = FileDialog.new()
	palette_save_dialog.access = FileDialog.ACCESS_FILESYSTEM
	palette_save_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	palette_save_dialog.title = "Save Palette PNG"
	palette_save_dialog.current_file = "my_palette.png"
	palette_save_dialog.filters = PackedStringArray(["*.png ; PNG Palette"])
	palette_save_dialog.file_selected.connect(func(path: String) -> void:
		if PaletteLoader.save_png(path, active_palette):
			status_label.text = "Palette saved  |  %s" % path
		else:
			status_label.text = "Could not save palette  |  %s" % path
	)
	add_child(palette_save_dialog)
	_build_export_dialog()

func _build_export_dialog() -> void:
	export_dialog = ConfirmationDialog.new()
	export_dialog.title = "Export Graph Output"
	export_dialog.confirmed.connect(func() -> void:
		export_settings["format"] = export_format_option.get_item_text(export_format_option.selected)
		export_settings["columns"] = int(export_columns_spin.value)
		export_settings["padding"] = int(export_padding_spin.value)
		export_columns = int(export_columns_spin.value)
		export_padding = int(export_padding_spin.value)
		_export_graph_output()
	)
	var column := VBoxContainer.new()
	export_format_option = OptionButton.new()
	for format in ["PNG", "SpriteSheet", "SpriteFrames"]:
		export_format_option.add_item(format)
	column.add_child(export_format_option)
	export_columns_spin = SpinBox.new()
	export_columns_spin.min_value = 1
	export_columns_spin.max_value = 64
	export_columns_spin.value = export_columns
	column.add_child(export_columns_spin)
	export_padding_spin = SpinBox.new()
	export_padding_spin.min_value = 0
	export_padding_spin.max_value = 128
	export_padding_spin.value = export_padding
	column.add_child(export_padding_spin)
	export_dialog.add_child(column)
	add_child(export_dialog)

func _make_panel(text: String) -> PanelContainer:
	var panel := PanelContainer.new()
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", Color("#c7cad4"))
	label.add_theme_constant_override("line_spacing", 6)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(label)
	return panel

func _on_file_menu_pressed(id: int) -> void:
	match id:
		1:
			_regenerate_frames()
		2:
			_open_project_dialog(FileDialog.FILE_MODE_SAVE_FILE)
		3:
			if export_dialog != null:
				export_dialog.popup_centered(Vector2i(320, 220))
		4:
			_open_project_dialog(FileDialog.FILE_MODE_OPEN_FILE)
		5:
			_export_png_frames()
		6:
			export_columns = frames.size()
			_export_sprite_sheet()
		7:
			export_columns = 1
			_export_sprite_sheet()
		8:
			export_columns = ceili(sqrt(float(frames.size())))
			_export_sprite_sheet()
		9:
			_export_godot_sprite_frames()
		10:
			_recover_autosave()
		11:
			_undo_pixel_edit()
		12:
			_redo_pixel_edit()
		13:
			get_tree().quit()
		20:
			_export_all()
		_:
			if id >= 100 and id < 100 + recent_projects.size():
				_load_project_from(recent_projects[id - 100])

func _open_project_dialog(mode: FileDialog.FileMode) -> void:
	file_dialog_mode = mode
	file_dialog.file_mode = mode
	file_dialog.title = "Save Haribon VFXForge Project" if mode == FileDialog.FILE_MODE_SAVE_FILE else "Load Haribon VFXForge Project"
	file_dialog.current_file = "current_effect.vfxproj" if mode == FileDialog.FILE_MODE_SAVE_FILE else ""
	file_dialog.popup_centered_ratio(0.7)

func _on_project_file_selected(path: String) -> void:
	recent_projects = ProjectManager.add_recent(recent_projects, path)
	ProjectManager.write(RECENT_PROJECTS_PATH, recent_projects)
	if file_dialog_mode == FileDialog.FILE_MODE_SAVE_FILE:
		_save_project_to(path)
	else:
		_load_project_from(path)

func _on_palette_file_selected(path: String) -> void:
	var loaded := PaletteLoader.load_png(path)
	if loaded.is_empty():
		status_label.text = "Could not load palette  |  %s" % path
		return
	active_palette = loaded
	active_palette_name = path.get_file().get_basename()
	using_ice_palette = false
	if graph_editor != null:
		graph_editor.update_node_parameter("Palette", "palette", active_palette_name)
	_refresh_palette_grid()
	_regenerate_frames()
	status_label.text = "Palette loaded  |  %d colors  |  %s" % [active_palette.size(), path]
	_refresh_palette_presets()

func _on_texture_file_selected(path: String) -> void:
	if graph_editor != null:
		graph_editor.update_node_parameter("Texture", "path", path)
	texture_path = path
	_regenerate_frames()
	status_label.text = "Texture loaded  |  %s" % path

func _refresh_palette_presets() -> void:
	if palette_selector == null:
		return
	palette_selector.clear()
	palette_selector.add_item("Fire")
	palette_selector.add_item("Ice")
	for pack in StylePackLibrary.builtins():
		palette_selector.add_item(String(pack.name))
	for palette_name in PaletteLibrary.scan_png_names():
		palette_selector.add_item(palette_name)
	var selected := -1
	for index in palette_selector.item_count:
		if palette_selector.get_item_text(index) == active_palette_name:
			selected = index
			break
	if selected >= 0:
		palette_selector.select(selected)
	_update_palette_status()

func _on_palette_preset_selected(index: int) -> void:
	if palette_selector == null:
		return
	var preset_name := palette_selector.get_item_text(index)
	if preset_name == "Fire":
		active_palette = fire_palette.duplicate()
		using_ice_palette = false
	elif preset_name == "Ice":
		active_palette = ice_palette.duplicate()
		using_ice_palette = true
	elif not StylePackLibrary.find(preset_name).is_empty():
		active_palette = StylePackLibrary.find(preset_name)
		using_ice_palette = false
	else:
		var loaded := PaletteLoader.load_png("res://palette/%s.png" % preset_name)
		if loaded.is_empty():
			status_label.text = "Could not load palette preset  |  %s" % preset_name
			return
		active_palette = loaded
		using_ice_palette = false
	active_palette_name = preset_name
	if graph_editor != null:
		graph_editor.update_node_parameter("Palette", "palette", active_palette_name)
	_refresh_palette_grid()
	_update_palette_status()
	_regenerate_frames()

func _update_palette_status() -> void:
	if palette_status_label != null:
		palette_status_label.text = "%s  |  %d colors" % [active_palette_name, active_palette.size()]

func _save_project() -> void:
	_save_project_to("res://exports/current_effect.vfxproj")
	_save_preferences()

func _save_project_to(path: String) -> void:
	var project := {
		"version": 1,
		"name": project_name,
		"canvas_size": [CANVAS_SIZE.x, CANVAS_SIZE.y],
		"seed": seed_value,
		"radius": radius,
		"intensity": intensity,
		"particle_count": particle_count,
		"spread": spread,
		"direction": direction,
		"frame_count": frames.size(),
		"fps": frames_per_second,
		"palette": active_palette.map(func(color: Color) -> String: return color.to_html(true)),
		"palette_name": active_palette_name,
		"renderer": renderer_mode,
		"export_settings": export_settings.duplicate(true),
		"frames": _serialize_frames(),
		"graph": graph_editor.serialize_state() if graph_editor != null else {},
	}
	DirAccess.make_dir_absolute("C:/projects/VFXForge/exports")
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string(ProjectCodec.encode(project))
		status_label.text = "Project saved  |  %s" % path

func _serialize_frames() -> Array:
	var serialized: Array = []
	for frame in frames:
		var pixels: Array = []
		for color in frame.pixels:
			pixels.append(color.to_html(true))
		serialized.append(pixels)
	return serialized

func _load_project() -> void:
	_load_project_from("res://exports/current_effect.vfxproj")

func _load_project_from(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		status_label.text = "No saved project found"
		return
	var parsed: Dictionary = ProjectCodec.decode(file.get_as_text())
	parsed = ProjectMigration.migrate(parsed)
	if not parsed is Dictionary:
		status_label.text = "Could not read saved project"
		return
	seed_value = int(parsed.get("seed", seed_value))
	project_name = String(parsed.get("name", project_name))
	global_seed_value = seed_value
	radius = int(parsed.get("radius", radius))
	intensity = float(parsed.get("intensity", intensity))
	particle_count = int(parsed.get("particle_count", particle_count))
	spread = float(parsed.get("spread", spread))
	direction = float(parsed.get("direction", direction))
	frame_count = int(parsed.get("frame_count", frame_count))
	frames_per_second = maxf(1.0, float(parsed.get("fps", frames_per_second)))
	var saved_palette = parsed.get("palette", [])
	if saved_palette is Array and not saved_palette.is_empty():
		active_palette.clear()
		for color_hex in saved_palette:
			active_palette.append(Color(String(color_hex)))
	active_palette_name = String(parsed.get("palette_name", active_palette_name))
	renderer_mode = String(parsed.get("renderer", renderer_mode))
	var saved_export_settings = parsed.get("export_settings", {})
	if saved_export_settings is Dictionary:
		export_settings = saved_export_settings.duplicate(true)
		export_padding = int(export_settings.get("padding", export_padding))
	var saved_frames = parsed.get("frames", [])
	var saved_graph = parsed.get("graph", {})
	if graph_editor != null and saved_graph is Dictionary and not saved_graph.is_empty():
		graph_editor.set_graph_state(saved_graph)
	if saved_frames is Array and not saved_frames.is_empty():
		frames.clear()
		for saved_pixels in saved_frames:
			var restored := PixelCanvas.new(CANVAS_SIZE)
			if saved_pixels is Array:
				for index in mini(saved_pixels.size(), restored.pixels.size()):
					restored.pixels[index] = Color(String(saved_pixels[index]))
			frames.append(restored)
		frame_count = frames.size()
		current_frame = 0
		pixel_canvas = frames[0]
	else:
		_regenerate_frames()
	if canvas_view != null:
		canvas_view.canvas = pixel_canvas
		canvas_view.queue_redraw()
	if seed_input != null:
		seed_input.text = str(seed_value)
	status_label.text = "Project loaded  |  %s" % path

func _save_preferences() -> void:
	preferences["last_renderer"] = renderer_mode
	PreferencesStore.write("user://haribon_vfxforge_preferences.json", preferences)

func _recover_autosave() -> void:
	var path := RecoveryManager.recovery_path()
	if not RecoveryManager.has_snapshot(path):
		status_label.text = "No recovery snapshot found"
		return
	_load_project_from(path)
	status_label.text = "Recovery snapshot loaded"

func _export_sprite_sheet() -> void:
	if frames.is_empty():
		return
	var frame_size := Vector2i(CANVAS_SIZE.x * CANVAS_PIXEL_SIZE, CANVAS_SIZE.y * CANVAS_PIXEL_SIZE)
	var columns: int = maxi(1, export_columns)
	var rows: int = ceili(float(frames.size()) / columns)
	var sheet := ImageExporter.make_sprite_sheet(_baked_output_frames(), columns, CANVAS_PIXEL_SIZE, export_padding)
	DirAccess.make_dir_absolute("C:/projects/VFXForge/exports")
	var filename := PresetLibrary.file_slug(active_preset_name) + "_spritesheet.png"
	sheet.save_png("res://exports/" + filename)
	status_label.text = "Sprite sheet exported  |  exports/" + filename

func _graph_output_format() -> String:
	if graph_editor == null:
		return "SpriteFrames"
	var state := graph_editor.get_graph_state()
	var evaluated: Dictionary = GraphEvaluator.evaluate(state.nodes, state.connections)
	return String(evaluated.get("output", "SpriteFrames"))

func _graph_renderer() -> String:
	if graph_editor == null:
		return renderer_mode
	var state := graph_editor.get_graph_state()
	var evaluated: Dictionary = GraphEvaluator.evaluate(state.nodes, state.connections)
	return String(evaluated.get("renderer", renderer_mode))

func _export_graph_output() -> void:
	var renderer := _graph_renderer()
	var capability := RendererContract.describe(renderer)
	if not bool(capability.get("deterministic", true)):
		status_label.text = "Preview-only renderer | Export uses deterministic pixel frames"
	var plan: Dictionary = ExportPlan.for_format(_graph_output_format())
	match plan.kind:
		"png_frames":
			_export_png_frames()
		"sprite_sheet":
			_export_sprite_sheet()
		_:
			_export_godot_sprite_frames()

func _export_all() -> void:
	_export_png_frames()
	var previous_columns := export_columns
	export_columns = frames.size()
	_export_sprite_sheet()
	export_columns = ceili(sqrt(float(frames.size())))
	_export_sprite_sheet()
	export_columns = previous_columns
	_export_godot_sprite_frames()
	status_label.text = "All exports written  |  exports/  |  %s" % PresetLibrary.file_slug(active_preset_name)

func _export_png_frames() -> void:
	if frames.is_empty():
		return
	DirAccess.make_dir_absolute("C:/projects/VFXForge/exports/frames")
	var folder := PresetLibrary.file_slug(active_preset_name)
	DirAccess.make_dir_absolute("C:/projects/VFXForge/exports/frames/" + folder)
	var output_frames := _baked_output_frames()
	for index in output_frames.size():
		var frame_image := ImageExporter.canvas_to_image(output_frames[index], CANVAS_PIXEL_SIZE)
		frame_image.save_png("res://exports/frames/%s/frame_%02d.png" % [folder, index + 1])
	status_label.text = "PNG frames exported  |  exports/frames/%s/" % folder

func _export_godot_sprite_frames() -> void:
	_export_png_frames()
	var folder := PresetLibrary.file_slug(active_preset_name)
	var file_path := "res://exports/haribon_%s_sprite_frames.tres" % folder
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if file != null:
		file.store_string(SpriteFramesExporter.build_resource(_baked_output_frames().size(), "res://exports/frames/%s" % folder, frames_per_second))
		status_label.text = "Godot SpriteFrames exported  |  " + file_path

func _canvas_to_image(source: PixelCanvas) -> Image:
	return ImageExporter.canvas_to_image(source, CANVAS_PIXEL_SIZE)

func _baked_output_frames() -> Array[PixelCanvas]:
	if not pixelize_enabled:
		return frames.duplicate()
	return FrameBaker.bake_frames(frames, pixelize_resolution)

func _apply_frame_layers() -> void:
	if mask_mode == "Radial":
		for index in frames.size():
			frames[index] = FrameBaker.apply_radial_mask(frames[index], mask_amount)
	if not texture_path.is_empty():
		var resolved_path := ProjectSettings.globalize_path(texture_path) if texture_path.begins_with("res://") else texture_path
		var image := Image.load_from_file(resolved_path)
		if image != null:
			for index in frames.size():
				frames[index] = FrameBaker.apply_texture_alpha(frames[index], image)

func _build_right_column() -> VBoxContainer:
	var right_column := VBoxContainer.new()
	right_column.custom_minimum_size.x = 210
	right_column.add_theme_constant_override("separation", 6)
	var color_panel := _build_color_panel()
	color_panel.size_flags_vertical = Control.SIZE_FILL
	color_panel.custom_minimum_size.y = 300
	right_column.add_child(color_panel)
	var inspector_panel := _build_inspector()
	inspector_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_column.add_child(inspector_panel)
	return right_column

func _build_color_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style())
	panel.theme = _ui_theme()
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.follow_focus = true
	panel.add_child(scroll)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(column)

	var title := Label.new()
	title.text = "COLOR & PALETTE"
	title.add_theme_color_override("font_color", ACCENT_COLOR)
	column.add_child(title)
	palette_selector = OptionButton.new()
	palette_selector.name = "PalettePresetSelector"
	palette_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	palette_selector.item_selected.connect(_on_palette_preset_selected)
	column.add_child(palette_selector)
	palette_status_label = Label.new()
	palette_status_label.add_theme_color_override("font_color", ACCENT_COLOR)
	column.add_child(palette_status_label)
	_refresh_palette_presets()
	var load_palette_button := Button.new()
	load_palette_button.text = "Load PNG..."
	load_palette_button.pressed.connect(func() -> void:
		palette_file_dialog.popup_centered_ratio(0.7)
	)
	column.add_child(load_palette_button)
	var save_palette_button := Button.new()
	save_palette_button.text = "Save Palette PNG..."
	save_palette_button.pressed.connect(func() -> void:
		palette_save_dialog.popup_centered_ratio(0.7)
	)
	column.add_child(save_palette_button)
	var color_label := Label.new()
	color_label.text = "Paint Color"
	column.add_child(color_label)
	color_picker_control = ColorPickerButton.new()
	color_picker_control.color = paint_color
	color_picker_control.custom_minimum_size = Vector2(0, 20)
	_style_color_picker(color_picker_control)
	color_picker_control.color_changed.connect(func(color: Color) -> void: paint_color = color)
	column.add_child(color_picker_control)
	palette_grid = GridContainer.new()
	palette_grid.columns = 4
	column.add_child(palette_grid)
	_refresh_palette_grid()
	var palette_actions := HBoxContainer.new()
	var add_color_button := Button.new()
	add_color_button.text = "+ Color"
	add_color_button.tooltip_text = "Add the current paint color to the active palette"
	add_color_button.pressed.connect(func() -> void:
		if not active_palette.has(paint_color):
			active_palette.append(paint_color)
			_refresh_palette_grid()
			_regenerate_frames()
			status_label.text = "Palette color added  |  %d colors" % active_palette.size()
	)
	palette_actions.add_child(add_color_button)
	var remove_color_button := Button.new()
	remove_color_button.text = "− Color"
	remove_color_button.tooltip_text = "Remove the last color from the active palette"
	remove_color_button.pressed.connect(func() -> void:
		if active_palette.size() > 1:
			active_palette.pop_back()
			_refresh_palette_grid()
			_regenerate_frames()
			status_label.text = "Palette color removed  |  %d colors" % active_palette.size()
	)
	palette_actions.add_child(remove_color_button)
	column.add_child(palette_actions)
	return panel

func _build_inspector() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style())
	panel.theme = _ui_theme()
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.follow_focus = true
	panel.add_child(scroll)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(column)

	var title := Label.new()
	title.text = "INSPECTOR\n\nImpact"
	title.add_theme_color_override("font_color", ACCENT_COLOR)
	column.add_child(title)
	selected_node_label = Label.new()
	selected_node_label.text = "Selected Node: none"
	selected_node_label.add_theme_color_override("font_color", Color("#8d9a98"))
	column.add_child(selected_node_label)
	node_parameters_container = VBoxContainer.new()
	node_parameters_container.add_theme_constant_override("separation", 4)
	column.add_child(node_parameters_container)

	column.add_child(_make_slider("Radius", 2.0, 16.0, radius, _on_radius_changed))
	column.add_child(_make_slider("Intensity", 0.1, 2.0, intensity, _on_intensity_changed))
	column.add_child(_make_slider("Particles", 10.0, 160.0, particle_count, _on_particle_count_changed))
	column.add_child(_make_slider("Spread", 0.4, 2.0, spread, _on_spread_changed))
	column.add_child(_make_slider("Direction", -3.14, 3.14, direction, _on_direction_changed))

	var seed_button := Button.new()
	seed_button.text = "Randomize Seed"
	seed_button.pressed.connect(_on_randomize_seed)
	column.add_child(seed_button)

	var seed_row := HBoxContainer.new()
	seed_input = LineEdit.new()
	seed_input.name = "SeedInput"
	seed_input.placeholder_text = "Enter seed"
	seed_input.text = str(seed_value)
	seed_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	seed_input.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER
	seed_row.add_child(seed_input)
	var apply_seed_button := Button.new()
	apply_seed_button.text = "Apply"
	apply_seed_button.pressed.connect(func() -> void:
		if seed_input.text.is_valid_int():
			seed_value = seed_input.text.to_int()
			global_seed_value = seed_value
			_sync_global_seed_to_node()
			_regenerate_frames()
	)
	seed_row.add_child(apply_seed_button)
	column.add_child(seed_row)

	var preset_label := Label.new()
	preset_label.text = "Preset"
	column.add_child(preset_label)
	preset_selector = OptionButton.new()
	for preset in PresetLibrary.builtins():
		preset_selector.add_item(String(preset.name))
	preset_selector.item_selected.connect(_on_preset_selected)
	column.add_child(preset_selector)
	var renderer_label := Label.new()
	renderer_label.text = "Renderer"
	column.add_child(renderer_label)
	renderer_selector = OptionButton.new()
	for renderer in RendererContract.supported():
		renderer_selector.add_item(renderer)
	renderer_selector.select(maxi(0, RendererContract.supported().find(renderer_mode)))
	renderer_selector.item_selected.connect(func(index: int) -> void:
		renderer_mode = renderer_selector.get_item_text(index)
		var capability := RendererContract.describe(renderer_mode)
		status_label.text = "%s | %s" % [renderer_mode, "Deterministic" if capability.deterministic else "Preview only"]
		if renderer_mode == RendererContract.GPU_PARTICLES:
			_restart_gpu_preview()
		elif renderer_mode == RendererContract.CPU_PARTICLES:
			if cpu_particle_preview != null:
				cpu_particle_preview.burst(global_seed_value, particle_count, spread * PI, 120.0)
	)
	column.add_child(renderer_selector)
	var gpu_button := Button.new()
	gpu_button.text = "Preview GPU Sparks"
	gpu_button.pressed.connect(_restart_gpu_preview)
	column.add_child(gpu_button)
	var bake_gpu_button := Button.new()
	bake_gpu_button.text = "Bake GPU Sparks to Frames"
	bake_gpu_button.pressed.connect(_bake_gpu_sparks)
	column.add_child(bake_gpu_button)
	var shader_button := Button.new()
	shader_button.text = "Toggle Shader Glow"
	shader_button.pressed.connect(_toggle_shader_preview)
	column.add_child(shader_button)
	var vector_button := Button.new()
	vector_button.text = "Toggle Vector Preview"
	vector_button.pressed.connect(func() -> void:
		if vector_preview != null:
			vector_preview.set_enabled(not vector_preview.visible)
	)
	column.add_child(vector_button)
	var onion_button := Button.new()
	onion_button.text = "Toggle Onion Skin"
	onion_button.pressed.connect(func() -> void:
		onion_skin_enabled = not onion_skin_enabled
		_update_onion_skin()
		status_label.text = "Onion skin %s" % ("enabled" if onion_skin_enabled else "disabled")
	)
	column.add_child(onion_button)
	var selection_button := Button.new()
	selection_button.text = "Toggle Select Region"
	selection_button.pressed.connect(func() -> void:
		canvas_view.selection_mode = not canvas_view.selection_mode
		selection_button.text = "Select Region: ON" if canvas_view.selection_mode else "Toggle Select Region"
		status_label.text = "Selection mode %s" % ("enabled" if canvas_view.selection_mode else "disabled")
	)
	column.add_child(selection_button)
	return panel

func _on_preset_selected(index: int) -> void:
	var presets := PresetLibrary.builtins()
	if index < 0 or index >= presets.size():
		return
	var preset: Dictionary = presets[index]
	active_preset_name = String(preset.name)
	renderer_mode = String(preset.get("renderer", RendererContract.PIXEL_CPU))
	if renderer_selector != null:
		renderer_selector.select(RendererContract.supported().find(renderer_mode))
	var recipe: Array = preset.get("recipe", [])
	var recipe_text := " → ".join(recipe) if not recipe.is_empty() else "Seed → Shape → Output"
	status_label.text = "Preset loaded  |  %s  |  %s  |  Recipe: %s" % [preset.name, renderer_mode, recipe_text]
	if graph_editor != null:
		graph_editor.set_graph_state(PresetLibrary.graph_for(String(preset.name)))
	if String(preset.get("generator", "")) == "impact":
		_regenerate_frames()

func _setup_gpu_preview() -> void:
	gpu_particles = GPUParticles2D.new()
	gpu_particles.amount = 48
	gpu_particles.lifetime = 0.7
	gpu_particles.one_shot = true
	gpu_particles.explosiveness = 1.0
	gpu_particles.randomness = 0.8
	gpu_particles.preprocess = 0.15
	gpu_particles.emitting = false
	gpu_particles.visibility_rect = Rect2(-512, -512, 1024, 1024)
	gpu_particles.z_index = 2
	var material := ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINT
	material.direction = Vector3(0, -1, 0)
	material.spread = 180.0
	material.initial_velocity_min = 80.0
	material.initial_velocity_max = 180.0
	material.gravity = Vector3(0, 100, 0)
	material.scale_min = 0.5
	material.scale_max = 1.0
	material.color = ACCENT_COLOR
	gpu_particles.process_material = material
	var image := Image.create(6, 6, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	gpu_particles.texture = ImageTexture.create_from_image(image)
	canvas_view.add_child(gpu_particles)
	cpu_particle_preview = CpuParticlePreview.new()
	cpu_particle_preview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cpu_particle_preview.z_index = 3
	canvas_view.add_child(cpu_particle_preview)
	vector_preview = VectorPreview.new()
	vector_preview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vector_preview.z_index = 4
	canvas_view.add_child(vector_preview)
	_update_gpu_preview_position()

func _on_graph_changed(node_order: Array[String], connection_count: int) -> void:
	_regenerate_frames()
	status_label.text = "Graph evaluated  |  %d nodes  |  %d connections" % [node_order.size(), connection_count]

func _on_graph_node_selected(node_type: String, parameters: Dictionary) -> void:
	if selected_node_label != null:
		selected_node_label.text = "Selected Node: %s" % node_type
	status_label.text = "Selected %s node  |  Parameters: %d" % [node_type, parameters.size()]
	_refresh_node_inspector(node_type, parameters)

func _refresh_node_inspector(node_type: String, parameters: Dictionary = {}) -> void:
	for child in node_parameters_container.get_children():
		child.queue_free()
	match node_type:
		"Seed":
			var seed_hint := Label.new()
			seed_hint.text = "Uses the global Seed field"
			seed_hint.add_theme_color_override("font_color", Color("#8d9a98"))
			node_parameters_container.add_child(seed_hint)
		"Burst":
			node_parameters_container.add_child(_make_slider("Radius", 2.0, 16.0, radius, _on_radius_changed))
			node_parameters_container.add_child(_make_slider("Intensity", 0.1, 2.0, intensity, _on_intensity_changed))
		"Palette":
			var palette_label := Label.new()
			palette_label.text = "Active: %s (%d colors)" % [active_palette_name, active_palette.size()]
			node_parameters_container.add_child(palette_label)
			var load_palette_button := Button.new()
			load_palette_button.text = "Load PNG Palette"
			load_palette_button.pressed.connect(func() -> void:
				palette_file_dialog.popup_centered_ratio(0.7)
			)
			node_parameters_container.add_child(load_palette_button)
		"Pixelize":
			var resolution := Label.new()
			resolution.text = "Enabled: %s\nOutput: %d × %d" % ["Yes" if pixelize_enabled else "No", pixelize_resolution.x, pixelize_resolution.y]
			node_parameters_container.add_child(resolution)
		"Mask":
			var mask_label := Label.new()
			mask_label.text = "Mode: %s\nAmount: %.2f" % [mask_mode if not mask_mode.is_empty() else "Inactive", mask_amount]
			node_parameters_container.add_child(mask_label)
		"Texture":
			var texture_label := Label.new()
			texture_label.text = "Source: %s" % (texture_path if not texture_path.is_empty() else "None")
			texture_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			node_parameters_container.add_child(texture_label)
			var load_texture_button := Button.new()
			load_texture_button.text = "Load PNG Texture"
			load_texture_button.pressed.connect(func() -> void:
				texture_file_dialog.popup_centered_ratio(0.7)
			)
			node_parameters_container.add_child(load_texture_button)
		"Output":
			var output := Button.new()
			output.text = "Format: %s" % _graph_output_format()
			output.pressed.connect(func() -> void:
				var formats: Array[String] = ["PNG", "SpriteSheet", "SpriteFrames"]
				var current := formats.find(_graph_output_format())
				var next_format: String = formats[(current + 1) % formats.size()]
				graph_editor.update_node_parameter("Output", "format", next_format)
				output.text = "Format: %s" % next_format
			)
			node_parameters_container.add_child(output)
		_:
			var description := String(_selected_node_property(node_type, "description", ""))
			if not description.is_empty():
				var description_label := Label.new()
				description_label.text = description
				description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				description_label.add_theme_color_override("font_color", Color("#8d9a98"))
				node_parameters_container.add_child(description_label)
			for parameter_name in parameters:
				var parameter_label := Label.new()
				parameter_label.text = String(parameter_name)
				node_parameters_container.add_child(parameter_label)
				var parameter_value = parameters[parameter_name]
				if parameter_value is int or parameter_value is float:
					var numeric := SpinBox.new()
					numeric.min_value = -100000.0
					numeric.max_value = 100000.0
					numeric.step = 0.1 if parameter_value is float else 1.0
					numeric.value = float(parameter_value)
					numeric.value_changed.connect(func(value: float) -> void:
						if graph_editor != null:
							graph_editor.update_node_parameter(node_type, String(parameter_name), value)
					)
					node_parameters_container.add_child(numeric)
				else:
					var text_input := LineEdit.new()
					text_input.text = String(parameter_value)
					text_input.text_submitted.connect(func(value: String) -> void:
						if graph_editor != null:
							graph_editor.update_node_parameter(node_type, String(parameter_name), value)
					)
					node_parameters_container.add_child(text_input)
	_setup_shader_preview()

func _selected_node_property(node_type: String, property_name: String, fallback: Variant) -> Variant:
	if graph_editor == null:
		return fallback
	for node in graph_editor.nodes:
		if String(node.get("name", "")) == node_type:
			return node.get(property_name, fallback)
	return fallback

func _setup_shader_preview() -> void:
	shader_preview = ColorRect.new()
	shader_preview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shader_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shader_preview.z_index = 1
	var shader := Shader.new()
	shader.code = "shader_type canvas_item;\nrender_mode unshaded;\nuniform vec4 glow_color : source_color = vec4(0.47, 1.0, 0.85, 1.0);\nuniform float intensity = 0.0;\nvoid fragment() { vec2 centered = UV - vec2(0.5); float radius = length(centered); float glow = smoothstep(0.42, 0.04, radius) * intensity; COLOR = vec4(glow_color.rgb, glow * 0.22); }"
	shader_material = ShaderMaterial.new()
	shader_material.shader = shader
	shader_material.set_shader_parameter("intensity", 0.0)
	shader_preview.material = shader_material
	canvas_view.add_child(shader_preview)

func _toggle_shader_preview() -> void:
	if shader_material == null:
		return
	var current: float = shader_material.get_shader_parameter("intensity")
	shader_material.set_shader_parameter("intensity", 0.0 if current > 0.0 else 1.0)

func _update_gpu_preview_position() -> void:
	if gpu_particles != null:
		gpu_particles.position = canvas_view.size / 2.0

func _restart_gpu_preview() -> void:
	_update_gpu_preview_position()
	if gpu_particles != null:
		gpu_particles.restart()
	if cpu_particle_preview != null:
		cpu_particle_preview.burst(global_seed_value, particle_count, spread * PI, 120.0)

func _bake_gpu_sparks() -> void:
	if status_label != null:
		status_label.text = "Baking GPU sparks  |  capturing transparent frames..."
	var images: Array[Image] = await gpu_bake_service.bake_burst(self, Vector2i(256, 256), frame_count, frames_per_second, ACCENT_COLOR)
	var baked := SubViewportBaker.images_to_pixel_canvases(images, CANVAS_SIZE)
	if baked.is_empty():
		status_label.text = "GPU bake failed  |  no frames captured"
		return
	frames = baked
	_apply_frame_layers()
	if active_preset_name == "Glow Impact" or renderer_mode == RendererContract.HYBRID:
		for index in frames.size():
			frames[index] = FrameCompositor.additive_glow(frames[index], 2, 0.22)
	current_frame = 0
	if frame_slider != null:
		frame_slider.max_value = maxi(0, frames.size() - 1)
	pixel_canvas = frames[0]
	if canvas_view != null:
		canvas_view.canvas = pixel_canvas
		canvas_view.queue_redraw()
	status_label.text = "GPU bake ready  |  %d frames captured  |  exportable" % frames.size()

func _refresh_palette_grid() -> void:
	if palette_grid == null:
		return
	for child in palette_grid.get_children():
		child.queue_free()
	for color in active_palette:
		var swatch := Button.new()
		swatch.custom_minimum_size = Vector2(30, 30)
		var swatch_style := StyleBoxFlat.new()
		swatch_style.bg_color = color
		swatch_style.set_corner_radius_all(3)
		swatch_style.set_border_width_all(1)
		swatch_style.border_color = Color("#52615f")
		swatch.add_theme_stylebox_override("normal", swatch_style)
		var hover_style: StyleBoxFlat = swatch_style.duplicate()
		hover_style.border_color = ACCENT_COLOR
		hover_style.set_border_width_all(2)
		swatch.add_theme_stylebox_override("hover", hover_style)
		swatch.tooltip_text = color.to_html(false)
		swatch.pressed.connect(func() -> void:
			paint_color = color
			color_picker_control.color = color
		)
		palette_grid.add_child(swatch)

func _make_slider(label_text: String, minimum: float, maximum: float, value: float, callback: Callable) -> VBoxContainer:
	var group := VBoxContainer.new()
	group.add_theme_constant_override("separation", 4)
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var value_label := Label.new()
	value_label.text = _format_value(value)
	value_label.add_theme_color_override("font_color", ACCENT_COLOR)
	row.add_child(value_label)
	group.add_child(row)
	var slider := HSlider.new()
	slider.min_value = minimum
	slider.max_value = maximum
	slider.step = 0.1 if label_text == "Intensity" else 1.0
	slider.value = value
	slider.custom_minimum_size.y = 10
	slider.add_theme_icon_override("grabber", _make_grabber(ACCENT_COLOR))
	slider.add_theme_icon_override("grabber_highlight", _make_grabber(ACCENT_COLOR))
	slider.add_theme_color_override("font_color", ACCENT_COLOR)
	slider.value_changed.connect(func(new_value: float) -> void:
		value_label.text = _format_value(new_value)
		callback.call(new_value)
	)
	group.add_child(slider)
	return group

func _format_value(value: float) -> String:
	return "%.1f" % value if value != floor(value) else "%d" % int(value)

func _make_grabber(color: Color) -> GradientTexture2D:
	var texture := GradientTexture2D.new()
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([color, color])
	texture.gradient = gradient
	texture.width = 12
	texture.height = 12
	return texture

func _ui_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = 12
	theme.default_base_scale = 1.0
	for control_type in ["Button", "Label", "LineEdit", "SpinBox", "OptionButton", "MenuBar", "PopupMenu", "CheckButton", "HSlider"]:
		theme.set_font_size("font_size", control_type, 12)
	return theme

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_COLOR
	style.border_color = Color("#303943")
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style

func _regenerate() -> void:
	_regenerate_frames()

func _regenerate_frames() -> void:
	_apply_graph_parameters()
	var state: Dictionary = graph_editor.get_graph_state() if graph_editor != null else {"nodes": [], "connections": []}
	var result := VFXPipeline.render({
		"canvas_size": CANVAS_SIZE,
		"nodes": state.nodes,
		"connections": state.connections,
		"fallback": {"seed": seed_value, "radius": radius, "intensity": intensity},
		"renderer_mode": renderer_mode,
		"preset_name": active_preset_name,
		"palette": active_palette,
		"particle_count": particle_count,
		"spread": spread,
		"direction": direction,
		"frame_count": frame_count,
		"texture_path": texture_path,
	})
	frames = result.frames
	var resolved_renderer := String(result.renderer)
	if renderer_mode != resolved_renderer:
		renderer_mode = resolved_renderer
		if renderer_selector != null:
			renderer_selector.select(RendererContract.supported().find(resolved_renderer))
	if frame_slider != null:
		frame_slider.max_value = maxi(0, frames.size() - 1)
	current_frame = clampi(current_frame, 0, frames.size() - 1)
	pixel_canvas = frames[current_frame]
	if canvas_view != null:
		canvas_view.canvas = pixel_canvas
		canvas_view.queue_redraw()
	if status_label != null:
		status_label.text = "Impact regenerated  |  Frame: %02d / %02d  |  Seed: %d" % [current_frame + 1, frames.size(), seed_value]

func _enforce_windowed_mode() -> void:
	var window := get_window()
	window.mode = Window.MODE_WINDOWED
	window.borderless = false
	window.unresizable = false
	window.size = Vector2i(1600, 900)
	window.position = Vector2i(160, 90)

func _show_frame(frame_index: int) -> void:
	current_frame = clampi(frame_index, 0, frames.size() - 1)
	pixel_canvas = frames[current_frame]
	canvas_view.canvas = pixel_canvas
	canvas_view.queue_redraw()
	_update_onion_skin()
	status_label.text = "Impact preview  |  Frame: %02d / %02d  |  Seed: %d" % [current_frame + 1, frames.size(), seed_value]

func _update_onion_skin() -> void:
	if canvas_view == null:
		return
	var previous: PixelCanvas = null
	var next: PixelCanvas = null
	if onion_skin_enabled and frames.size() > 1:
		previous = frames[(current_frame - 1 + frames.size()) % frames.size()]
		next = frames[(current_frame + 1) % frames.size()]
	canvas_view.onion_previous = previous
	canvas_view.onion_next = next
	canvas_view.queue_redraw()

func _build_timeline() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style())
	var timeline_theme := _ui_theme()
	panel.theme = timeline_theme
	var column := VBoxContainer.new()
	panel.add_child(column)
	var row := HBoxContainer.new()
	play_button = Button.new()
	play_button.text = "▶ Play"
	play_button.pressed.connect(_on_play_pressed)
	row.add_child(play_button)
	var duplicate_button := Button.new()
	duplicate_button.text = "Duplicate"
	duplicate_button.pressed.connect(_duplicate_frame)
	row.add_child(duplicate_button)
	var delete_button := Button.new()
	delete_button.text = "Delete"
	delete_button.pressed.connect(_delete_frame)
	row.add_child(delete_button)
	var key_button := Button.new()
	key_button.text = "Key Intensity"
	key_button.pressed.connect(func() -> void:
		_key_current_parameter("intensity", intensity)
	)
	row.add_child(key_button)
	for parameter_name in ["radius", "spread", "direction"]:
		var parameter_button := Button.new()
		parameter_button.text = "Key " + parameter_name.capitalize()
		parameter_button.pressed.connect(func() -> void:
			_key_current_parameter(parameter_name, _parameter_value(parameter_name))
		)
		row.add_child(parameter_button)
	var frame_label := Label.new()
	frame_label.text = "Frame"
	row.add_child(frame_label)
	var frame_count_spin := SpinBox.new()
	frame_count_spin.name = "FrameCount"
	frame_count_spin.min_value = 1
	frame_count_spin.max_value = 120
	frame_count_spin.step = 1
	frame_count_spin.value = frame_count
	frame_count_spin.tooltip_text = "Animation frame count"
	frame_count_spin.value_changed.connect(func(value: float) -> void:
		frame_count = int(value)
		_regenerate_frames()
	)
	row.add_child(frame_count_spin)
	var fps_label := Label.new()
	fps_label.text = "FPS"
	row.add_child(fps_label)
	var fps_spin := SpinBox.new()
	fps_spin.name = "FPS"
	fps_spin.min_value = 1
	fps_spin.max_value = 120
	fps_spin.step = 1
	fps_spin.value = frames_per_second
	fps_spin.tooltip_text = "Animation playback and export rate"
	fps_spin.value_changed.connect(func(value: float) -> void:
		frames_per_second = value
		_update_timeline_hint()
	)
	row.add_child(fps_spin)
	frame_slider = HSlider.new()
	frame_slider.min_value = 0
	frame_slider.max_value = 11
	frame_slider.step = 1
	frame_slider.value = 0
	frame_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frame_slider.value_changed.connect(func(value: float) -> void: _show_frame(int(value)))
	row.add_child(frame_slider)
	column.add_child(row)
	timeline_hint = Label.new()
	timeline_hint.name = "TimelineHint"
	timeline_hint.text = "%d frames  |  %d FPS  |  Loop enabled" % [frame_count, int(frames_per_second)]
	timeline_hint.add_theme_color_override("font_color", Color("#8d9a98"))
	column.add_child(timeline_hint)
	return panel

func _update_timeline_hint() -> void:
	if timeline_hint != null:
		timeline_hint.text = "%d frames  |  %d FPS  |  Loop enabled" % [frame_count, int(frames_per_second)]

func _parameter_value(parameter_name: String) -> float:
	match parameter_name:
		"radius": return float(radius)
		"spread": return spread
		"direction": return direction
		_: return intensity

func _key_current_parameter(parameter_name: String, value: float) -> void:
	parameter_animation.add_key(parameter_name, float(current_frame) / maxf(1.0, frames_per_second), value)
	status_label.text = "%s key added  |  frame %d" % [parameter_name.capitalize(), current_frame]

func _copy_canvas(source: PixelCanvas) -> PixelCanvas:
	var copy := PixelCanvas.new(source.size)
	copy.pixels = source.pixels.duplicate()
	return copy

func _duplicate_frame() -> void:
	frames.insert(current_frame + 1, _copy_canvas(frames[current_frame]))
	frame_slider.max_value = frames.size() - 1
	_show_frame(current_frame + 1)

func _delete_frame() -> void:
	if frames.size() <= 1:
		return
	frames.remove_at(current_frame)
	current_frame = mini(current_frame, frames.size() - 1)
	frame_slider.max_value = frames.size() - 1
	_show_frame(current_frame)

func _on_pixel_pressed(position: Vector2i, erase: bool = false) -> void:
	if not Rect2i(Vector2i.ZERO, pixel_canvas.size).has_point(position):
		return
	pixel_history.record(pixel_canvas)
	pixel_canvas.set_pixel(position, Color.TRANSPARENT if erase else paint_color)
	frames[current_frame] = pixel_canvas
	canvas_view.queue_redraw()

func _undo_pixel_edit() -> void:
	pixel_canvas = pixel_history.undo(pixel_canvas)
	frames[current_frame] = pixel_canvas
	canvas_view.canvas = pixel_canvas
	canvas_view.queue_redraw()
	status_label.text = "Pixel edit undone"

func _redo_pixel_edit() -> void:
	pixel_canvas = pixel_history.redo(pixel_canvas)
	frames[current_frame] = pixel_canvas
	canvas_view.canvas = pixel_canvas
	canvas_view.queue_redraw()
	status_label.text = "Pixel edit redone"

func _on_play_pressed() -> void:
	is_playing = not is_playing
	if not is_playing:
		playback_accumulator = 0.0
	play_button.text = "⏸ Pause" if is_playing else "▶ Play"

func _process(_delta: float) -> void:
	_update_gpu_preview_position()
	autosave_elapsed += _delta
	var autosave_minutes := float(preferences.get("autosave_minutes", 5))
	if autosave_minutes > 0.0 and autosave_elapsed >= autosave_minutes * 60.0:
		autosave_elapsed = 0.0
		_save_project_to(RecoveryManager.recovery_path())
	if is_playing and not frames.is_empty():
		var playback := PlaybackClock.advance(playback_accumulator, _delta, frames_per_second)
		playback_accumulator = float(playback.accumulator)
		if int(playback.steps) <= 0:
			return
		var time := float(current_frame) / maxf(1.0, frames_per_second)
		var animated_intensity := parameter_animation.sample("intensity", time, intensity)
		var animated_radius := parameter_animation.sample("radius", time, float(radius))
		var animated_spread := parameter_animation.sample("spread", time, spread)
		var animated_direction := parameter_animation.sample("direction", time, direction)
		intensity = animated_intensity
		radius = int(round(animated_radius))
		spread = animated_spread
		direction = animated_direction
		if graph_editor != null:
			graph_editor.set_node_parameter_silent("Burst", "intensity", intensity)
			graph_editor.set_node_parameter_silent("Burst", "radius", radius)
		_regenerate()
		current_frame = (current_frame + 1) % frames.size()
		frame_slider.set_value_no_signal(current_frame)
		_show_frame(current_frame)

func _style_color_picker(button: ColorPickerButton) -> void:
	var solid := StyleBoxFlat.new()
	solid.bg_color = Color("#20242b")
	solid.border_color = Color("#52615f")
	solid.set_border_width_all(1)
	solid.set_corner_radius_all(4)
	var popup := button.get_popup()
	popup.add_theme_stylebox_override("panel", solid)
	var picker := button.get_picker()
	picker.add_theme_stylebox_override("panel", solid)
	picker.add_theme_color_override("font_color", TEXT_COLOR)

func _on_radius_changed(value: float) -> void:
	radius = int(value)
	if graph_editor != null:
		graph_editor.update_node_parameter("Burst", "radius", radius)
	_regenerate()

func _on_intensity_changed(value: float) -> void:
	intensity = value
	if graph_editor != null:
		graph_editor.update_node_parameter("Burst", "intensity", intensity)
	_regenerate()

func _on_particle_count_changed(value: float) -> void:
	particle_count = int(value)
	_regenerate()

func _on_spread_changed(value: float) -> void:
	spread = value
	_regenerate()

func _on_direction_changed(value: float) -> void:
	direction = value
	_regenerate()

func _on_randomize_seed() -> void:
	seed_value = randi()
	global_seed_value = seed_value
	if seed_input != null:
		seed_input.text = str(seed_value)
	_sync_global_seed_to_node()
	_regenerate()

func _sync_global_seed_to_node() -> void:
	if graph_editor == null:
		return
	if bool(graph_editor.get_node_parameter("Seed", "use_global_seed", true)):
		graph_editor.set_node_parameter_silent("Seed", "seed", global_seed_value)

func _sync_seed_node_controls() -> void:
	if graph_editor == null:
		return
	if bool(graph_editor.get_node_parameter("Seed", "use_global_seed", true)):
		seed_value = int(graph_editor.get_node_parameter("Seed", "seed", global_seed_value))
	else:
		seed_value = global_seed_value

func _apply_graph_parameters() -> void:
	if graph_editor == null:
		return
	_sync_global_seed_to_node()
	var state := graph_editor.get_graph_state()
	var evaluated := GraphEvaluator.evaluate(state.nodes, state.connections, {
		"seed": seed_value,
		"radius": radius,
		"intensity": intensity,
		"palette": "Ice" if using_ice_palette else "Fire",
	})
	if bool(graph_editor.get_node_parameter("Seed", "use_global_seed", true)):
		evaluated.seed = global_seed_value
	seed_value = int(evaluated.seed)
	radius = int(evaluated.radius)
	intensity = float(evaluated.intensity)
	pixelize_enabled = bool(evaluated.get("has_pixelize", false))
	pixelize_resolution = Vector2i(maxi(1, int(evaluated.resolution)), maxi(1, int(evaluated.resolution))) if pixelize_enabled else CANVAS_SIZE
	mask_mode = String(evaluated.get("mask_mode", "")) if bool(evaluated.get("has_mask", false)) else ""
	mask_amount = float(evaluated.get("mask_amount", 1.0))
	texture_path = String(evaluated.get("texture_path", ""))
	var evaluated_palette := String(evaluated.palette)
	if evaluated_palette == "Ice":
		using_ice_palette = true
		active_palette_name = "Ice"
		active_palette = ice_palette
	elif evaluated_palette == "Fire":
		using_ice_palette = false
		active_palette_name = "Fire"
		active_palette = fire_palette
	if seed_input != null:
		seed_input.text = str(seed_value)


class PixelCanvasView extends Control:
	signal pixel_pressed(position: Vector2i, erase: bool)
	signal selection_created(area: Rect2i)
	signal selection_moved(destination: Vector2i)
	var canvas: PixelCanvas
	var pixel_size := 12
	var zoom := 1.0
	var pan := Vector2.ZERO
	var panning := false
	var last_mouse_position := Vector2.ZERO
	var onion_previous: PixelCanvas
	var onion_next: PixelCanvas
	var selection_mode := false
	var selecting := false
	var selection_start := Vector2i.ZERO
	var selection_end := Vector2i.ZERO
	var selection_bounds := Rect2i()
	var moving_selection := false
	var move_offset := Vector2i.ZERO

	func _ready() -> void:
		focus_mode = Control.FOCUS_ALL
		mouse_entered.connect(func() -> void: grab_focus())

	func _draw() -> void:
		if canvas == null:
			return
		var scaled_size := Vector2(canvas.size * pixel_size) * zoom
		var origin := (size - scaled_size) / 2.0 + pan
		draw_rect(Rect2(origin, scaled_size), Color("#20242d"), true)
		_draw_onion_frame(onion_previous, origin, Color("#ff6688", 0.25))
		_draw_onion_frame(onion_next, origin, Color("#78bfff", 0.25))
		for y in canvas.size.y:
			for x in canvas.size.x:
				var position := Vector2(x, y) * pixel_size * zoom + origin
				var color := canvas.get_pixel(Vector2i(x, y))
				if color.a > 0.0:
					draw_rect(Rect2(position, Vector2.ONE * pixel_size * zoom), color, true)
		for x in range(canvas.size.x + 1):
			var grid_x := origin.x + x * pixel_size * zoom
			draw_line(Vector2(grid_x, origin.y), Vector2(grid_x, origin.y + scaled_size.y), Color("#3b414d"), 1.0, false)
		for y in range(canvas.size.y + 1):
			var grid_y := origin.y + y * pixel_size * zoom
			draw_line(Vector2(origin.x, grid_y), Vector2(origin.x + scaled_size.x, grid_y), Color("#3b414d"), 1.0, false)
		if selecting or selection_mode and selection_end != selection_start:
			var selection_rect := Rect2(selection_start, selection_end - selection_start + Vector2i.ONE)
			var pixel_rect := Rect2(origin + Vector2(selection_rect.position) * pixel_size * zoom, selection_rect.size * pixel_size * zoom)
			draw_rect(pixel_rect, Color("#78ffd9", 0.85), false, 2.0)

	func _draw_onion_frame(source: PixelCanvas, origin: Vector2, tint: Color) -> void:
		if source == null:
			return
		for y in source.size.y:
			for x in source.size.x:
				var color := source.get_pixel(Vector2i(x, y))
				if color.a > 0.0:
					color = Color(tint.r, tint.g, tint.b, tint.a)
					draw_rect(Rect2(origin + Vector2(x, y) * pixel_size * zoom, Vector2.ONE * pixel_size * zoom), color, true)

	func _gui_input(event: InputEvent) -> void:
		if canvas == null:
			return
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == KEY_F:
				_fit_canvas()
				accept_event()
				return
			if event.keycode == KEY_1:
				zoom = 1.0
				queue_redraw()
				accept_event()
				return
			if event.keycode == KEY_0:
				zoom = 1.0
				pan = Vector2.ZERO
				queue_redraw()
				accept_event()
				return
		if selection_mode:
			if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
				var point := _mouse_to_pixel(get_local_mouse_position())
				if event.pressed:
					if selection_bounds.size != Vector2i.ZERO and selection_bounds.has_point(point):
						moving_selection = true
						move_offset = point - selection_bounds.position
						selection_start = selection_bounds.position
						selection_end = selection_bounds.end - Vector2i.ONE
					else:
						selecting = true
						selection_start = point
						selection_end = point
				else:
					if moving_selection:
						moving_selection = false
						selection_moved.emit(point - move_offset)
					else:
						selecting = false
						selection_end = point
						var area := Rect2i(selection_start, selection_end - selection_start + Vector2i.ONE).abs()
						selection_created.emit(area)
				queue_redraw()
				accept_event()
				return
			if event is InputEventMouseMotion and selecting:
				selection_end = _mouse_to_pixel(get_local_mouse_position())
				queue_redraw()
				accept_event()
				return
			if event is InputEventMouseMotion and moving_selection:
				var point := _mouse_to_pixel(get_local_mouse_position())
				selection_start = point - move_offset
				selection_end = selection_start + selection_bounds.size - Vector2i.ONE
				queue_redraw()
				accept_event()
				return
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MIDDLE:
			panning = event.pressed
			last_mouse_position = event.position
			accept_event()
			return
		if event is InputEventMouseButton and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			zoom = clampf(zoom * (1.25 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 0.8), 0.5, 16.0)
			queue_redraw()
			accept_event()
			return
		if event is InputEventMouseMotion and panning:
			pan += event.position - last_mouse_position
			last_mouse_position = event.position
			queue_redraw()
			accept_event()
			return
		var is_painting := false
		var erase := false
		var event_position := Vector2.ZERO
		if event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
			is_painting = true
			erase = event.button_index == MOUSE_BUTTON_RIGHT
			event_position = get_local_mouse_position()
		elif event is InputEventMouseMotion and event.button_mask & (MOUSE_BUTTON_MASK_LEFT | MOUSE_BUTTON_MASK_RIGHT):
			is_painting = true
			erase = bool(event.button_mask & MOUSE_BUTTON_MASK_RIGHT)
			event_position = get_local_mouse_position()
		if is_painting:
			var pixel := _mouse_to_pixel(event_position)
			pixel_pressed.emit(pixel, erase)

	func _mouse_to_pixel(mouse_position: Vector2) -> Vector2i:
		var scaled_size := Vector2(canvas.size * pixel_size) * zoom
		var origin := (size - scaled_size) / 2.0 + pan
		return Vector2i(floor((mouse_position - origin) / (pixel_size * zoom)))

	func _fit_canvas() -> void:
		if canvas == null or canvas.size.x <= 0 or canvas.size.y <= 0:
			return
		var available := size - Vector2(24, 24)
		zoom = clampf(minf(available.x / float(canvas.size.x * pixel_size), available.y / float(canvas.size.y * pixel_size)), 0.5, 16.0)
		pan = Vector2.ZERO
		queue_redraw()
