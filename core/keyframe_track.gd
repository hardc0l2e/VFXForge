class_name KeyframeTrack
extends RefCounted

var keys: Array[Dictionary] = []

func add_key(time: float, value: float) -> void:
	keys.append({"time": maxf(0.0, time), "value": value})
	keys.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.time) < float(b.time))

func sample(time: float, fallback: float = 0.0) -> float:
	if keys.is_empty():
		return fallback
	if time <= float(keys[0].time):
		return float(keys[0].value)
	for index in range(keys.size() - 1):
		var left: Dictionary = keys[index]
		var right: Dictionary = keys[index + 1]
		if time <= float(right.time):
			var duration := float(right.time) - float(left.time)
			var weight := 0.0 if is_zero_approx(duration) else inverse_lerp(float(left.time), float(right.time), time)
			return lerpf(float(left.value), float(right.value), weight)
	return float(keys.back().value)

func serialize() -> Array[Dictionary]:
	return keys.duplicate(true)
