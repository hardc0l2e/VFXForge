class_name OnionSkin
extends RefCounted

static func overlay(previous: PixelCanvas, next: PixelCanvas, previous_opacity := 0.25, next_opacity := 0.25) -> Dictionary:
	return {
		"previous": previous,
		"next": next,
		"previous_opacity": clampf(previous_opacity, 0.0, 1.0),
		"next_opacity": clampf(next_opacity, 0.0, 1.0),
	}
