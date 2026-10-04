extends SceneTree

## Headless test entry point — runs every McpTestSuite in res://tests/
## without a live editor session:
##
##   Godot --headless --path <project> -s res://tests/run_headless.gd
##
## Discovery mirrors test_handler.gd: files in res://tests/ named test_*.gd
## whose script instantiates to an McpTestSuite. Exit codes:
##   0 = all tests passed (load errors still fail the run)
##   1 = at least one test failed
##   2 = discovery failed (no tests directory / no suites / load errors)

const TestRunner := preload("res://tests/harness/test_runner.gd")
const TestSuite := preload("res://tests/harness/test_suite.gd")


func _init() -> void:
	var exit_code := 0
	var suites: Array = []
	var load_errors: Array[String] = []

	var dir := DirAccess.open("res://tests")
	if dir == null:
		printerr("RUNNER | cannot open res://tests")
		quit(2)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while not file_name.is_empty():
		if file_name.begins_with("test_") and file_name.ends_with(".gd"):
			var path := "res://tests/" + file_name
			var script = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
			if script == null:
				load_errors.append("%s (load failed)" % file_name)
			elif script.can_instantiate():
				var instance = script.new()
				if instance is TestSuite:
					suites.append(instance)
				else:
					load_errors.append("%s (not a test suite subclass)" % file_name)
			else:
				var reload_error: Error = script.reload(true)
				load_errors.append(
					"%s (cannot instantiate; reload=%s)" % [file_name, error_string(reload_error)]
				)
		file_name = dir.get_next()
	dir.list_dir_end()

	suites.sort_custom(func(a, b) -> bool:
		return a.suite_name() < b.suite_name()
	)

	if suites.is_empty():
		printerr("RUNNER | no test suites found in res://tests/")
		quit(2)
		return

	var runner = TestRunner.new()
	## No service callback / deadline: legacy fully-synchronous path.
	var run: Dictionary = runner.run_suites(suites, "", "", {}, true)
	var failed := int(run.get("failed", 0))
	var passed := int(run.get("passed", 0))
	var skipped := int(run.get("skipped", 0))
	var total := int(run.get("total", 0))

	for r in run.get("results", []):
		if r.get("skipped", false):
			print("SKIP  %s / %s — %s" % [r.suite, r.test, r.get("message", "")])
		elif r.passed:
			print("PASS  %s / %s (%d assertions, %dms)" % [
				r.suite, r.test, int(r.get("assertion_count", 0)), int(r.get("duration_ms", 0))
			])
		else:
			print("FAIL  %s / %s — %s" % [r.suite, r.test, r.get("message", "")])

	if not load_errors.is_empty():
		for e in load_errors:
			printerr("LOAD  %s" % e)
		exit_code = 2

	if exit_code == 0 and failed > 0:
		exit_code = 1

	print("RUNNER | %d passed, %d failed, %d skipped, %d total (%dms)" % [
		passed, failed, skipped, total, int(run.get("duration_ms", 0))
	])
	quit(exit_code)
