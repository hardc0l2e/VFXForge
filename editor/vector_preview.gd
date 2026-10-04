class_name VectorPreview
extends Control

const VectorShapes = preload("res://core/vector_shapes.gd")
var control_points := PackedVector2Array([Vector2(-80, 40), Vector2(-30, -90), Vector2(30, 90), Vector2(80, -40)])
var enabled := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false

func set_enabled(value: bool) -> void:
	enabled = value
	visible = value
	queue_redraw()

func _draw() -> void:
	if not enabled or control_points.size() < 4:
		return
	var offset := size * 0.5
	var points := VectorShapes.bezier_points(control_points[0], control_points[1], control_points[2], control_points[3], 24)
	var translated := PackedVector2Array()
	for point in points:
		translated.append(point + offset)
	draw_polyline(translated, Color("#78ffd9"), 2.0, true)
