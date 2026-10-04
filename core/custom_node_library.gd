class_name CustomNodeLibrary
extends RefCounted

const CustomNodeDefinition = preload("res://core/custom_node_definition.gd")

static func load_directory(path: String) -> Dictionary:
	var result := {"nodes": [], "errors": []}
	var directory := DirAccess.open(path)
	if directory == null:
		return result
	directory.list_dir_begin()
	var file_name := directory.get_next()
	while not file_name.is_empty():
		if not directory.current_is_dir() and file_name.to_lower().ends_with(".json"):
			_load_file(path.path_join(file_name), result)
		file_name = directory.get_next()
	directory.list_dir_end()
	return result

static func _load_file(path: String, result: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		result.errors.append("Could not open %s" % path)
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		result.errors.append("Invalid JSON node definition: %s" % path)
		return
	var definition := CustomNodeDefinition.new(String(parsed.get("name", "")))
	definition.category = String(parsed.get("category", "Custom"))
	definition.description = String(parsed.get("description", ""))
	for input_name in parsed.get("inputs", []):
		definition.add_input(String(input_name))
	for output_name in parsed.get("outputs", []):
		definition.add_output(String(output_name))
	var parameters = parsed.get("parameters", {})
	if parameters is Dictionary:
		for parameter_name in parameters:
			definition.add_parameter(String(parameter_name), parameters[parameter_name])
	var errors := definition.validate()
	if errors.is_empty():
		result.nodes.append(definition.serialize())
	else:
		result.errors.append("%s: %s" % [path, ", ".join(errors)])
