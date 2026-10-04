class_name SpriteFramesExporter
extends RefCounted

static func build_resource(frame_count: int, texture_directory: String = "res://exports/frames", fps: float = 24.0) -> String:
	var count := maxi(1, frame_count)
	var lines: Array[String] = ["[gd_resource type=\"SpriteFrames\" load_steps=%d format=3]" % (count + 1)]
	var frame_entries: Array[String] = []
	for index in count:
		var resource_id := "%d_frame" % (index + 1)
		lines.append("\n[ext_resource type=\"Texture2D\" path=\"%s/frame_%02d.png\" id=\"%s\"]" % [texture_directory, index + 1, resource_id])
		frame_entries.append("{\"duration\": 1.0, \"texture\": ExtResource(\"%s\")}" % resource_id)
	lines.append("\n[resource]\nanimations = [{\"frames\": [%s], \"loop\": true, \"name\": &\"default\", \"speed\": %.3f}]" % [", ".join(frame_entries), maxf(1.0, fps)])
	return "\n".join(lines)
