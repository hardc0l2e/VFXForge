class_name CustomNodeRuntime
extends RefCounted

static func execute(definition: Dictionary, inputs: Dictionary, context: Dictionary, executor: Callable) -> Dictionary:
	var errors: Array[String] = []
	var required_inputs = definition.get("inputs", [])
	if required_inputs is Array:
		for input_name in required_inputs:
			if not inputs.has(String(input_name)):
				errors.append("Missing input: %s" % String(input_name))
	if not errors.is_empty():
		return {"ok": false, "errors": errors, "outputs": {}}
	if not executor.is_valid():
		return {"ok": false, "errors": ["Custom node executor is not available"], "outputs": {}}
	var value = executor.call(inputs, context, definition.get("parameters", {}))
	if not value is Dictionary:
		return {"ok": false, "errors": ["Custom node executor must return a Dictionary"], "outputs": {}}
	return {"ok": true, "errors": [], "outputs": value}
