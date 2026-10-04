class_name RendererContract
extends RefCounted

const PIXEL_CPU := "Pixel CPU"
const GPU_PARTICLES := "GPU Particles"
const CPU_PARTICLES := "CPU Particles"
const SHADER := "Shader"
const HYBRID := "Hybrid"

static func describe(renderer: String) -> Dictionary:
	match renderer:
		PIXEL_CPU: return {"name": PIXEL_CPU, "deterministic": true, "preview": false, "bake": true}
		GPU_PARTICLES: return {"name": GPU_PARTICLES, "deterministic": false, "preview": true, "bake": false}
		CPU_PARTICLES: return {"name": CPU_PARTICLES, "deterministic": true, "preview": true, "bake": true}
		SHADER: return {"name": SHADER, "deterministic": false, "preview": true, "bake": false}
		HYBRID: return {"name": HYBRID, "deterministic": false, "preview": true, "bake": false}
		_: return {"name": PIXEL_CPU, "deterministic": true, "preview": false, "bake": true}

static func supported() -> Array[String]:
	return [PIXEL_CPU, GPU_PARTICLES, CPU_PARTICLES, SHADER, HYBRID]
