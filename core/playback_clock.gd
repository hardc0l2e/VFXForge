class_name PlaybackClock
extends RefCounted

static func advance(accumulator: float, delta: float, frames_per_second: float) -> Dictionary:
	var interval := 1.0 / maxf(1.0, frames_per_second)
	var elapsed := maxf(0.0, accumulator) + maxf(0.0, delta)
	var steps := 0
	while elapsed >= interval and steps < 8:
		elapsed -= interval
		steps += 1
	return {"accumulator": elapsed, "steps": steps}
