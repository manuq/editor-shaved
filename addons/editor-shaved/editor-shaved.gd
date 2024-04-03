@tool
extends EditorPlugin

const SINGLE_WINDOW_MODE_PROPERTY := "interface/editor/single_window_mode"

const Utils := preload("core/utils.gd")
const EditorInterfaceAccess := preload("core/editor_interface_access.gd")

const BUTTON_TOP_BAR = preload("button_top_bar.tscn")
const CANVAS_CONTROL = preload("canvas_control.tscn")
const SIMPLE_EDITOR = preload("simple_editor.tscn")
const EDITOR_TRANSITION = preload("editor_transition.tscn")
const EDIT_SCENE: String = "res://scenes/main.tscn"
enum { LEVEL_TYPE_TOPDOWN, LEVEL_TYPE_PLATFORMER }
enum { GOAL_REACH_BLOCK, GOAL_GRAB_FLOWERS }
const DEFAULT_TIMEOUT: float = 60.0
const DEFAULT_GRAVITY: float = 980.0

var editor_interface_access: EditorInterfaceAccess = null

var _simple_editor: Control = null
var _button_top_bar: Button = null
var _godot_editor: Control = null
var _canvas_control: Control = null
var _editor_transition: CanvasLayer = null
var _config: ConfigFile = ConfigFile.new()
var _config_filename: String = EditorInterface.get_editor_paths().get_project_settings_dir() + "/simple_editor.cfg"

func _enter_tree():
	await get_tree().physics_frame
	get_viewport().mode = Window.MODE_MAXIMIZED

	var editor_settings: EditorSettings = EditorInterface.get_editor_settings()
	var is_single_window_mode := editor_settings.get_setting(SINGLE_WINDOW_MODE_PROPERTY)
	if not is_single_window_mode:
			editor_settings.set_setting(SINGLE_WINDOW_MODE_PROPERTY, true)
			EditorInterface.restart_editor()
	
	scene_changed.connect(_on_scene_changed)

	editor_interface_access = EditorInterfaceAccess.new()
	_setup_canvas_control()
	_add_top_bar_button()
	
	_godot_editor = EditorInterface.get_base_control()

	_setup_custom_settings()

	if get_enabled():
		_show_simple_editor(true)


func _on_scene_changed(scene_root) -> void:
	if _simple_editor:
		_simple_editor.on_scene_loaded()

func get_enabled() -> bool:
	var err = _config.load(_config_filename)
	if err != OK:
		return true

	return _config.get_value("simple_editor", "enabled")


func set_enabled(enabled: bool) -> void:
	_config.set_value("simple_editor", "enabled", enabled)
	_config.save(_config_filename)
	

func _half_transition():
		_editor_transition = EDITOR_TRANSITION.instantiate()
		_godot_editor.get_parent().add_child(_editor_transition)
		_editor_transition.transition()
		await _editor_transition.half_completed


func _end_transition():
		await _editor_transition.completed
		# _godot_editor.get_parent().remove_child(_editor_transition)
		_editor_transition = null


func _setup_canvas_control() -> void:
	_canvas_control = CANVAS_CONTROL.instantiate()

func _clear_simple_editor() -> void:
	_simple_editor.scene_unloaded()
	_simple_editor.clear_canvas()
	_simple_editor.queue_free()
	await _simple_editor.tree_exited
	_simple_editor = null


func _setup_custom_settings() -> void:
	if not ProjectSettings.has_setting("custom/level_type"):
		ProjectSettings.set_setting("custom/level_type", LEVEL_TYPE_TOPDOWN)
		ProjectSettings.add_property_info({
			"name": "custom/level_type",
			"type": TYPE_INT,
			"hint": PROPERTY_HINT_ENUM,
			"hint_string": "top-down,platformer",	
		})
		ProjectSettings.set_initial_value("custom/level_type", LEVEL_TYPE_TOPDOWN)

	if not ProjectSettings.has_setting("custom/goal"):
		ProjectSettings.set_setting("custom/goal", GOAL_REACH_BLOCK)
		ProjectSettings.add_property_info({
			"name": "custom/goal",
			"type": TYPE_INT,
			"hint": PROPERTY_HINT_ENUM,
			"hint_string": "reach goal block,grab all flowers",	
		})
		ProjectSettings.set_initial_value("custom/goal", GOAL_REACH_BLOCK)

	if not ProjectSettings.has_setting("custom/timeout"):
		ProjectSettings.set_setting("custom/timeout", DEFAULT_TIMEOUT)
		ProjectSettings.add_property_info({
			"name": "custom/timeout",
			"type": TYPE_FLOAT,
		})
		ProjectSettings.set_initial_value("custom/timeout", DEFAULT_TIMEOUT)


func _setup_simple_editor() -> void:
	if _simple_editor:
		_clear_simple_editor()

	_simple_editor = SIMPLE_EDITOR.instantiate()
	_simple_editor.show_godot_editor.connect(_show_godot_editor)
	_simple_editor.play.connect(_on_play)
	_godot_editor.get_parent().add_child(_simple_editor)
	_simple_editor.hide()

	EditorInterface.set_main_screen_editor("2D")
	EditorInterface.open_scene_from_path(EDIT_SCENE)


func _add_top_bar_button() -> void:
		_button_top_bar = BUTTON_TOP_BAR.instantiate()
		_button_top_bar.pressed.connect(_show_simple_editor)
		editor_interface_access.run_bar.add_sibling(_button_top_bar)
		_button_top_bar.get_parent().move_child(_button_top_bar, editor_interface_access.run_bar.get_index())

func _show_godot_editor(exiting: bool = false) -> void:
	await _half_transition()

	EditorInterface.save_scene()
	# remove_control_from_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_BOTTOM, _canvas_control)

	if not exiting:
		set_enabled(false)
	_clear_simple_editor()

	_godot_editor.show()
	_simple_editor.hide()

	await _end_transition()

func _show_simple_editor(starting: bool = false) -> void:

	if not starting:
		await _half_transition()

	_setup_simple_editor()

	# add_control_to_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_BOTTOM, _canvas_control)
	_simple_editor.add_canvas(editor_interface_access.canvas_item_editor)
	_godot_editor.hide()
	_simple_editor.show()
	set_enabled(true)

	if not starting:
		await _end_transition()


func _on_play():
	EditorInterface.play_current_scene()


func _exit_tree():
	_show_godot_editor(true)
	# editor_interface_access.clean_up()
	# editor_interface_access.inspector_dock.show()
	_button_top_bar.queue_free()
	_simple_editor.queue_free()
