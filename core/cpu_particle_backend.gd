class_name CpuParticleBackend
extends RefCounted

static func emit(seed: int, count: int, spread: float, speed: float) -> Array[Dictionary]:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var particles: Array[Dictionary] = []
	for index in maxi(0, count):
		var angle := rng.randf_range(-spread, spread)
		particles.append({"position": Vector2.ZERO, "velocity": Vector2.RIGHT.rotated(angle) * speed, "life": 1.0, "index": index})
	return particles

static func advance(particles: Array[Dictionary], delta: float, damping: float = 0.96) -> Array[Dictionary]:
	var next: Array[Dictionary] = []
	for particle in particles:
		var copy := particle.duplicate(true)
		copy["position"] = copy.position + copy.velocity * delta
		copy["velocity"] = copy.velocity * pow(damping, delta * 60.0)
		copy["life"] = maxf(0.0, float(copy.life) - delta)
		next.append(copy)
	return next

static func bake_frames(canvas_size: Vector2i, seed: int, count: int, frame_count: int, spread: float, speed: float, delta: float, color: Color = Color.WHITE) -> Array[PixelCanvas]:
	var frames: Array[PixelCanvas] = []
	var particles := emit(seed, count, spread, speed)
	for frame_index in maxi(1, frame_count):
		var canvas := PixelCanvas.new(canvas_size)
		var center := Vector2(canvas_size) / 2.0
		for particle in particles:
			var point := Vector2i(round(center + particle.position))
			canvas.set_pixel(point, color)
		frames.append(canvas)
		particles = advance(particles, delta)
	return frames
