class_name ExportPlan
extends RefCounted

static func for_format(format: String) -> Dictionary:
	match format:
		"PNG":
			return {"kind": "png_frames", "extension": "png", "requires_textures": false}
		"SpriteSheet":
			return {"kind": "sprite_sheet", "extension": "png", "requires_textures": false}
		_:
			return {"kind": "godot_sprite_frames", "extension": "tres", "requires_textures": true}

static func is_supported(format: String) -> bool:
	return format in ["PNG", "SpriteSheet", "SpriteFrames"]
