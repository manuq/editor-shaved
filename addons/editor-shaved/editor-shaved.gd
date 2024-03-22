@tool
extends EditorPlugin

const SINGLE_WINDOW_MODE_PROPERTY := "interface/editor/single_window_mode"

const Utils := preload("core/utils.gd")
const EditorInterfaceAccess := preload("core/editor_interface_access.gd")

const BUTTON_TOP_BAR = preload("button_top_bar.tscn")
const EDITOR = preload("simple-editor.tscn")

var editor_interface_access: EditorInterfaceAccess = null

var _simple_editor: SimpleEditor = null
var _button_top_bar: Button = null
var _godot_editor: Control = null


func _enter_tree():
	await get_tree().physics_frame
	get_viewport().mode = Window.MODE_MAXIMIZED

	var editor_settings := EditorInterface.get_editor_settings()
	var is_single_window_mode := editor_settings.get_setting(SINGLE_WINDOW_MODE_PROPERTY)
	if not is_single_window_mode:
			editor_settings.set_setting(SINGLE_WINDOW_MODE_PROPERTY, true)
			EditorInterface.restart_editor()

	editor_interface_access = EditorInterfaceAccess.new()
	_add_top_bar_button()

func _add_top_bar_button() -> void:
		_button_top_bar = BUTTON_TOP_BAR.instantiate()
		_button_top_bar.pressed.connect(_replace_editor)
		editor_interface_access.run_bar.add_sibling(_button_top_bar)
		_button_top_bar.get_parent().move_child(_button_top_bar, editor_interface_access.run_bar.get_index())

func _show_godot_editor() -> void:
	_godot_editor.show()
	_simple_editor.hide()	
	
func _replace_editor() -> void:
	if not _godot_editor:
		_godot_editor = editor_interface_access.main_screen # editor_interface_access.inspector_dock
		
	if not _simple_editor:
		_simple_editor = EDITOR.instantiate()
		_simple_editor.show_godot_editor.connect(_show_godot_editor)
		_godot_editor.get_parent().add_child(_simple_editor)

	_godot_editor.hide()
	_simple_editor.show()

func _exit_tree():
	editor_interface_access.clean_up()
	editor_interface_access.inspector_dock.show()
	_button_top_bar.queue_free()
	_simple_editor.queue_free()
