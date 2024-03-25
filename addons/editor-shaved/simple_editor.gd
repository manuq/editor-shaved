@tool
extends Control
class_name SimpleEditor


signal show_godot_editor
signal play

const AVATAR = preload("res://scenes/entities/avatar.tscn")
const GOAL = preload("res://scenes/entities/goal.tscn")
const WALL = preload("res://scenes/entities/wall.tscn")
const FLOWER_ITEM = preload("res://scenes/entities/flower_item.tscn")

var _scene_root: Node = null
var _entities: Node2D = null
var _canvas: Control = null
var _canvas_parent: Control = null
var _entity_selected: Node2D = null

enum { LEVEL_TYPE_TOPDOWN, LEVEL_TYPE_PLATFORMER }
enum { GOAL_REACH_BLOCK, GOAL_GRAB_FLOWERS }

func _on_button_pressed() -> void:
	show_godot_editor.emit()


func add_canvas(canvas: VBoxContainer) -> void:
	_canvas = canvas
	_canvas_parent = canvas.get_parent()
	_canvas.reparent(%CanvasContainer, false)


func clear_canvas() -> void:
	_canvas.reparent(_canvas_parent, false)


func on_scene_loaded() -> void:
	_scene_root = EditorInterface.get_edited_scene_root()
	if not _scene_root:
		print("This is not the scene we want")
		return
	if not _scene_root.has_node("Entities"):
		print("This is not the scene we want either")
		return
	_entities = _scene_root.get_node("Entities")
	EditorInterface.get_selection().selection_changed.connect(_on_selection_changed)
	_on_selection_changed()
	_entities.child_entered_tree.connect(_on_added_entity)
	_entities.child_exiting_tree.connect(_on_removing_entity)
	_update_play_button()
	%GravityEdit.value = ProjectSettings.get_setting("physics/2d/default_gravity")
	%TimeoutEdit.value = ProjectSettings.get_setting("custom/timeout")
	var level_type = ProjectSettings.get_setting("custom/level_type")
	if level_type == LEVEL_TYPE_TOPDOWN:
		%TopDownButton.set_pressed_no_signal(true)
	else:
		%PlarformerButton.set_pressed_no_signal(true)
	var goal = ProjectSettings.get_setting("custom/goal")
	if goal == GOAL_GRAB_FLOWERS:
		%GrabFlowersButton.set_pressed_no_signal(true)
	else:
		%ReachGoalButton.set_pressed_no_signal(true)


func scene_unloaded() -> void:
	if not _entities:
		return
	EditorInterface.get_selection().selection_changed.disconnect(_on_selection_changed)
	_entities.child_entered_tree.disconnect(_on_added_entity)
	_entities.child_entered_tree.disconnect(_on_removing_entity)
	_entities = null
	_scene_root = null

func _ready():
	on_scene_loaded()

func _on_selection_changed() -> void:
	var node = null
	var selection = EditorInterface.get_selection()
	for n in selection.get_selected_nodes():
		if n is Node2D and n in _entities.get_children():
			node = n
			break

	if node:
		_entity_selected = node
		%LabelSelected.text = "Selected: " + node.name
		if not %DeleteButton.visible:
			%DeleteButton.show()
			%DeleteButton.disabled = false
		if node is Avatar:
			%AvatarGridContainer.visible = true 
			%AvatarSpeedEdit.set_value_no_signal(_entity_selected.SPEED)
			%AvatarJumpEdit.set_value_no_signal(_entity_selected.JUMP_VELOCITY)
		elif %AvatarGridContainer.visible:
			%AvatarGridContainer.hide()
	else:
		_entity_selected = null
		%LabelSelected.text = "Selected: none"
		if %DeleteButton.visible:
			%DeleteButton.hide()
			%DeleteButton.disabled = true
		if %AvatarGridContainer.visible:
			%AvatarGridContainer.hide()


func _update_play_button() -> void:
	%PlayButton.disabled = not _entities.get_child_count()


func _on_added_entity(node: Node) -> void:
	_update_play_button()


func _on_removing_entity(node: Node) -> void:
	await node.tree_exited
	_update_play_button()


func _on_play_button_pressed():
	play.emit()


func _on_quit_button_pressed():
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)


func _add_entity(scene: PackedScene):
	var node = scene.instantiate()
	_entities.add_child(node, true)
	node.set_owner(_scene_root)
	var w = ProjectSettings.get_setting("display/window/size/viewport_width")
	var h = ProjectSettings.get_setting("display/window/size/viewport_height")
	node.position = Vector2(w/2, h/2)
	#EditorInterface.edit_node(node)
	#var inspector: EditorInspector = EditorInterface.get_inspector()
	#for p in node.get_property_list():
		## if p["usage"] & PROPERTY_USAGE_GROUP:
		## if p["usage"] & PROPERTY_USAGE_SUBGROUP:
		#if p["name"] == "rotation":
			#print(p["usage"] & PROPERTY_USAGE_EDITOR)
			#print(p["usage"] & PROPERTY_USAGE_STORAGE)
			#print(p["usage"] & PROPERTY_USAGE_GROUP)
			#print(p)

func _on_avatar_button_pressed():
	_add_entity(AVATAR)

func _on_wall_button_pressed():
	_add_entity(WALL)

func _on_goal_button_pressed():
	_add_entity(GOAL)

func _on_flower_item_button_pressed():
	_add_entity(FLOWER_ITEM)


func _on_delete_button_pressed():
	var selection = EditorInterface.get_selection()
	for node in selection.get_selected_nodes():
		if node is Node2D and node in _entities.get_children():
			node.queue_free()


func _on_gravity_changed(value):
	ProjectSettings.set_setting("physics/2d/default_gravity", value)
	ProjectSettings.save()

func _on_top_down_button_pressed():
	ProjectSettings.set_setting("custom/level_type", LEVEL_TYPE_TOPDOWN)
	ProjectSettings.save()


func _on_plarformer_button_pressed():
	ProjectSettings.set_setting("custom/level_type", LEVEL_TYPE_PLATFORMER)
	ProjectSettings.save()


func _on_reach_goal_button_pressed():
	ProjectSettings.set_setting("custom/goal", GOAL_REACH_BLOCK)
	ProjectSettings.save()


func _on_grab_flowers_button_pressed():
	ProjectSettings.set_setting("custom/goal", GOAL_GRAB_FLOWERS)
	ProjectSettings.save()


func _on_timeout_changed(value):
	ProjectSettings.set_setting("custom/timeout", value)
	ProjectSettings.save()


func _on_avatar_speed_edit_value_changed(value):
	if _entity_selected is Avatar:
		_entity_selected.SPEED = value


func _on_avatar_jump_edit_value_changed(value):
	if _entity_selected is Avatar:
		_entity_selected.JUMP_VELOCITY = value
