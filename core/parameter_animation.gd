class_name ParameterAnimation
extends RefCounted

const KeyframeTrack = preload("res://core/keyframe_track.gd")
var tracks: Dictionary = {}

func add_key(parameter: String, time: float, value: float) -> void:
	if not tracks.has(parameter):
		tracks[parameter] = KeyframeTrack.new()
	tracks[parameter].add_key(time, value)

func sample(parameter: String, time: float, fallback: float = 0.0) -> float:
	if not tracks.has(parameter):
		return fallback
	return tracks[parameter].sample(time, fallback)

func serialize() -> Dictionary:
	var result := {}
	for parameter in tracks:
		result[parameter] = tracks[parameter].serialize()
	return result
