class_name ProjectMigration
extends RefCounted

const CURRENT_VERSION := 2

static func validate(project: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	if not project.has("canvas_size"):
		errors.append("canvas_size is required")
	if not project.has("frames"):
		errors.append("frames are required")
	elif not project.frames is Array:
		errors.append("frames must be an array")
	if project.has("canvas_size"):
		var canvas_size = project.canvas_size
		if not canvas_size is Array or canvas_size.size() != 2 or int(canvas_size[0]) <= 0 or int(canvas_size[1]) <= 0:
			errors.append("canvas_size must contain two positive dimensions")
	if project.has("fps") and float(project.fps) <= 0.0:
		errors.append("fps must be positive")
	return errors

static func migrate(project: Dictionary) -> Dictionary:
	var result := project.duplicate(true)
	var version := int(result.get("version", 1))
	if version < 2:
		result["renderer"] = String(result.get("renderer", "Pixel CPU"))
		result["version"] = 2
	return result
