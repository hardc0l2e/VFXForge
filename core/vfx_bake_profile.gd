class_name VFXBakeProfile
extends RefCounted

var resolution := Vector2i(256, 256)
var frame_count := 24
var fps := 24.0
var orthographic_scale := 4.0
var supersample := 2
var transparent_background := true
var output_modes: Array[String] = ["Raster", "Pixel", "SpriteFrames"]

func to_dictionary() -> Dictionary:
	return {
		"resolution": [resolution.x, resolution.y],
		"frame_count": frame_count,
		"fps": fps,
		"orthographic_scale": orthographic_scale,
		"supersample": supersample,
		"transparent_background": transparent_background,
		"output_modes": output_modes.duplicate(),
	}

static func from_dictionary(data: Dictionary):
	var profile = new()
	var size: Array = data.get("resolution", [256, 256])
	if size.size() >= 2:
		profile.resolution = Vector2i(maxi(1, int(size[0])), maxi(1, int(size[1])))
	profile.frame_count = clampi(int(data.get("frame_count", 24)), 1, 240)
	profile.fps = maxf(1.0, float(data.get("fps", 24.0)))
	profile.orthographic_scale = maxf(0.1, float(data.get("orthographic_scale", 4.0)))
	profile.supersample = clampi(int(data.get("supersample", 2)), 1, 8)
	profile.transparent_background = bool(data.get("transparent_background", true))
	var modes = data.get("output_modes", profile.output_modes)
	if modes is Array:
		profile.output_modes.clear()
		for mode in modes:
			profile.output_modes.append(String(mode))
	return profile
