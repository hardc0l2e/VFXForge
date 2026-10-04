extends Control

const PresetLibrary = preload("res://core/preset_library.gd")
const ACCENT := Color("#78ffd9")
const PRESET_NAMES := ["Projectile", "Spark Burst", "AOE Attack"]

var details: Label
var preview: PresetPreview
var play_button: Button

func _ready() -> void:
	var background := ColorRect.new()
	background.color = Color("#111519")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_bottom", 24)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	margin.add_child(root)
	var title := Label.new()
	title.text = "HARIBON VFXFORGE  |  PRESET RECIPE DEMO"
	title.add_theme_color_override("font_color", ACCENT)
	title.add_theme_font_size_override("font_size", 20)
	root.add_child(title)
	var instruction := Label.new()
	instruction.text = "Select a recipe to review the intended projectile, spark, or area-attack structure."
	root.add_child(instruction)
	var cards := HBoxContainer.new()
	cards.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cards.custom_minimum_size.y = 160
	cards.add_theme_constant_override("separation", 12)
	root.add_child(cards)
	for preset_name in PRESET_NAMES:
		var card := VBoxContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var button := Button.new()
		button.text = preset_name
		button.custom_minimum_size.y = 44
		button.pressed.connect(func() -> void: _show_preset(preset_name))
		card.add_child(button)
		var recipe_label := Label.new()
		var preset := PresetLibrary.find(preset_name)
		recipe_label.text = "Recipe\n%s" % " → ".join(preset.get("recipe", []))
		recipe_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.add_child(recipe_label)
		cards.add_child(card)
	var lower := HBoxContainer.new()
	lower.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lower.custom_minimum_size.y = 260
	root.add_child(lower)
	preview = PresetPreview.new()
	preview.custom_minimum_size = Vector2(640, 320)
	preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lower.add_child(preview)
	details = Label.new()
	details.custom_minimum_size.x = 420
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lower.add_child(details)
	play_button = Button.new()
	play_button.text = "⏸ Pause"
	play_button.pressed.connect(func() -> void:
		preview.playing = not preview.playing
		play_button.text = "⏸ Pause" if preview.playing else "▶ Play"
	)
	root.add_child(play_button)
	_show_preset("Projectile")

func _show_preset(preset_name: String) -> void:
	var preset := PresetLibrary.find(preset_name)
	if preset.is_empty():
		return
	details.text = "%s\n\n%s\n\nRenderer: %s\nGenerator: %s\n\nBuild this in the graph from left to right, then connect the final stage to Output." % [preset_name, preset.get("description", ""), preset.get("renderer", ""), preset.get("generator", "")]
	preview.preset_name = preset_name
	preview.queue_redraw()

class PresetPreview extends Control:
	var preset_name := "Projectile"
	var playing := true
	var phase := 0.0

	func _process(delta: float) -> void:
		if playing:
			phase = fmod(phase + delta, 2.0)
			queue_redraw()

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color("#18232a"), true)
		var center := size * 0.5
		match preset_name:
			"Projectile": _draw_projectile(center)
			"Spark Burst": _draw_sparks(center)
			"AOE Attack": _draw_aoe(center)

	func _draw_projectile(center: Vector2) -> void:
		var travel := fposmod(phase / 2.0, 1.0)
		var head := Vector2(90.0 + travel * maxf(80.0, size.x - 180.0), center.y)
		for index in 7:
			var tail := head - Vector2(18.0 + index * 15.0, 0)
			draw_circle(tail, maxf(2.0, 8.0 - index), Color(0.47, 1.0, 0.85, 0.9 - index * 0.1))
		draw_circle(head, 13.0, Color("#fff4c2"))
		draw_circle(head, 7.0, Color("#78ffd9"))

	func _draw_sparks(center: Vector2) -> void:
		var pulse := 0.5 + 0.5 * sin(phase * PI * 2.0)
		for index in 18:
			var angle := TAU * float(index) / 18.0
			var radius := 24.0 + pulse * 85.0 + float(index % 3) * 12.0
			var point := center + Vector2(cos(angle), sin(angle)) * radius
			draw_line(center + Vector2(cos(angle), sin(angle)) * 18.0, point, Color("#ffcf5c"), 4.0)
			draw_circle(point, 4.0, Color("#fff4c2"))
		draw_circle(center, 20.0 + pulse * 8.0, Color("#f2764b"))

	func _draw_aoe(center: Vector2) -> void:
		var pulse := fposmod(phase / 2.0, 1.0)
		for ring in 3:
			var radius := 28.0 + fmod(pulse + ring * 0.25, 1.0) * 125.0
			var alpha := 0.85 - ring * 0.2
			draw_arc(center, radius, 0.0, TAU, 64, Color(0.65, 0.25, 0.7, alpha), 5.0)
		for index in 12:
			var angle := TAU * float(index) / 12.0
			var point := center + Vector2(cos(angle), sin(angle)) * (45.0 + pulse * 70.0)
			draw_circle(point, 5.0, Color("#ff9b6a"))
		draw_circle(center, 22.0, Color("#78ffd9"))
