class_name FieldMath
extends RefCounted

static func scalar(operation: String, a: float, b: float = 0.0) -> float:
	match operation:
		"add": return a + b
		"subtract": return a - b
		"multiply": return a * b
		"divide": return a / b if not is_zero_approx(b) else 0.0
		"min": return minf(a, b)
		"max": return maxf(a, b)
		"clamp": return clampf(a, 0.0, b)
		_: return a

static func vector(operation: String, a: Vector2, b: Vector2 = Vector2.ZERO) -> Vector2:
	match operation:
		"add": return a + b
		"subtract": return a - b
		"multiply": return Vector2(a.x * b.x, a.y * b.y)
		"scale": return a * b.x
		"normalize": return a.normalized()
		"rotate": return a.rotated(b.x)
		_: return a

static func remap(value: float, from_min: float, from_max: float, to_min: float, to_max: float) -> float:
	if is_zero_approx(from_max - from_min):
		return to_min
	return lerpf(to_min, to_max, inverse_lerp(from_min, from_max, value))
