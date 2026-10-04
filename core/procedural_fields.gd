class_name ProceduralFields
extends RefCounted

static func noise_2d(position: Vector2, seed: int = 0, scale: float = 1.0) -> float:
	var sample := position * maxf(0.0001, scale)
	var value := sin(sample.x * 12.9898 + float(seed) * 0.017) * 43758.5453
	var second := cos(sample.y * 78.233 + float(seed) * 0.031) * 12741.371
	var raw := sin(value + second) * 0.5 + 0.5
	return raw - floor(raw)

static func radial_falloff(position: Vector2, radius: float = 1.0) -> float:
	if radius <= 0.0:
		return 0.0
	return clampf(1.0 - position.length() / radius, 0.0, 1.0)

static func remap_noise(position: Vector2, seed: int, scale: float, out_min: float, out_max: float) -> float:
	return lerpf(out_min, out_max, noise_2d(position, seed, scale))
