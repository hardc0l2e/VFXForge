class_name CpuParticlePreview
extends Control

const Backend = preload("res://core/cpu_particle_backend.gd")
var particles: Array[Dictionary] = []
var seed_value := 391822
var particle_count := 48
var spread := 3.14
var speed := 120.0
var playing := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)

func burst(seed: int, count: int, burst_spread: float = 3.14, burst_speed: float = 120.0) -> void:
	seed_value = seed
	particle_count = count
	spread = burst_spread
	speed = burst_speed
	particles = Backend.emit(seed_value, particle_count, spread, speed)
	playing = true
	queue_redraw()

func _process(delta: float) -> void:
	if not playing:
		return
	particles = Backend.advance(particles, delta)
	if particles.all(func(particle: Dictionary) -> bool: return float(particle.get("life", 0.0)) <= 0.0):
		playing = false
	queue_redraw()
	return
	queue_redraw()

func _draw() -> void:
	var center := size * 0.5
	for particle in particles:
		var life := clampf(float(particle.get("life", 0.0)), 0.0, 1.0)
		var position: Vector2 = center + particle.get("position", Vector2.ZERO)
		draw_circle(position, 2.0, Color(0.47, 1.0, 0.85, life))
