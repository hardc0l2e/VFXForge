class_name RecoveryManager
extends RefCounted

static func recovery_path(base_directory: String = "user://") -> String:
	return base_directory.path_join("haribon_vfxforge_recovery.vfxproj")

static func save_snapshot(path: String, project: Dictionary) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(project))
	return true

static func has_snapshot(path: String) -> bool:
	return FileAccess.file_exists(path)
