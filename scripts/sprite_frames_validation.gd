extends Node2D

static func find_sprite_frames_path(directory: String = "res://exports") -> String:
	var dir := DirAccess.open(directory)
	if dir == null:
		return ""
	var candidates: Array[String] = []
	dir.list_dir_begin()
	var filename := dir.get_next()
	while filename != "":
		if not dir.current_is_dir() and filename.ends_with("_sprite_frames.tres"):
			candidates.append(directory.path_join(filename))
		filename = dir.get_next()
	dir.list_dir_end()
	if candidates.is_empty() and ResourceLoader.exists(directory.path_join("haribon_impact_sprite_frames.tres")):
		return directory.path_join("haribon_impact_sprite_frames.tres")
	candidates.sort()
	return candidates[0] if not candidates.is_empty() else ""

func _ready() -> void:
	var sprite := get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	var status := get_node_or_null("Status") as Label
	var sprite_frames: SpriteFrames = null
	var sprite_frames_path := find_sprite_frames_path()
	if not sprite_frames_path.is_empty() and ResourceLoader.exists(sprite_frames_path):
		sprite_frames = load(sprite_frames_path) as SpriteFrames
	if sprite_frames == null:
		if status != null:
			status.text = "SpriteFrames export not found. Export from Haribon VFXForge first."
		return
	if not sprite_frames.has_animation("default"):
		if status != null:
			status.text = "SpriteFrames loaded, but default animation is missing."
		return
	sprite.sprite_frames = sprite_frames
	sprite.animation = &"default"
	sprite.play()
	if status != null:
		status.text = "SpriteFrames playback valid  |  %d frames  |  %.1f FPS" % [sprite_frames.get_frame_count(&"default"), sprite_frames.get_animation_speed(&"default")]
