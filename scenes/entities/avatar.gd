class_name Avatar extends CharacterBody2D


@export var SPEED = 300.0
@export var JUMP_VELOCITY = 650.0

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

enum { LEVEL_TYPE_TOPDOWN, LEVEL_TYPE_PLATFORMER }
var level_type = null

func _ready():
	%AnimationPlayer.animation_set_next("jump", "idle")
	# %AnimationPlayer.set_blend_time("jump", "idle", 0.2)
	level_type = ProjectSettings.get_setting("custom/level_type", LEVEL_TYPE_TOPDOWN)

func _physics_process_topdown(delta):
	var direction = Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up", "ui_down"),
	)
	if direction:
		velocity = direction * SPEED
		if direction.x:
			if direction.x > 0 and %AnimationPlayer.current_animation != "walk-right":
				%AnimationPlayer.play("walk-right")
			elif direction.x < 0 and %AnimationPlayer.current_animation != "walk-left":
				%AnimationPlayer.play("walk-left")
		else:
			if %AnimationPlayer.current_animation != "idle":
				%AnimationPlayer.play("idle")
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.y = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

func _physics_process_platformer(delta):
	if not is_on_floor():
		velocity.y += gravity * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = -JUMP_VELOCITY
		%AnimationPlayer.stop()
		%AnimationPlayer.play("jump")

	var direction = Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
		if is_on_floor() and %AnimationPlayer.current_animation != "jump":
			if direction > 0 and %AnimationPlayer.current_animation != "walk-right":
				%AnimationPlayer.play("walk-right")
			elif direction < 0 and %AnimationPlayer.current_animation != "walk-left":
				%AnimationPlayer.play("walk-left")
	else:
		if is_on_floor() and %AnimationPlayer.current_animation not in ["idle", "jump"]:
			%AnimationPlayer.play("idle")
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

func _physics_process(delta):
	if level_type == LEVEL_TYPE_TOPDOWN:
		_physics_process_topdown(delta)
	elif level_type == LEVEL_TYPE_PLATFORMER:
		_physics_process_platformer(delta)
