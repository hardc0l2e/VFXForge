class_name VectorShapes
extends RefCounted

static func line_points(from: Vector2, to: Vector2, subdivisions: int = 1) -> PackedVector2Array:
	var result := PackedVector2Array()
	var count := maxi(1, subdivisions)
	for index in count + 1:
		result.append(from.lerp(to, float(index) / float(count)))
	return result

static func bezier_points(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, subdivisions: int = 16) -> PackedVector2Array:
	var result := PackedVector2Array()
	var count := maxi(1, subdivisions)
	for index in count + 1:
		var t := float(index) / float(count)
		var inverse := 1.0 - t
		result.append(inverse * inverse * inverse * p0 + 3.0 * inverse * inverse * t * p1 + 3.0 * inverse * t * t * p2 + t * t * t * p3)
	return result

static func polygon_center(points: PackedVector2Array) -> Vector2:
	if points.is_empty():
		return Vector2.ZERO
	var total := Vector2.ZERO
	for point in points:
		total += point
	return total / float(points.size())
