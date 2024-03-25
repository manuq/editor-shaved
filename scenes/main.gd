extends Node2D

enum { GOAL_REACH_BLOCK, GOAL_GRAB_FLOWERS }
var goal_type = null
var finished = false

var timer = null
var total_flowers = 0
var flowers_grabbed = 0

func _ready():
	%Win.hide()
	%GameOver.hide()

	goal_type = ProjectSettings.get_setting("custom/goal", GOAL_REACH_BLOCK)

	for node in %Entities.get_children():
		if node is Goal:
			node.goal_reached.connect(_on_goal_reached)
		elif node is FlowerItem:
			total_flowers += 1
			node.flower_grabbed.connect(_on_flower_grabbed)

	timer = get_tree().create_timer(ProjectSettings.get_setting("custom/timeout", 60.0))
	timer.timeout.connect(_on_timer_timeout)

func _process(delta):
	%TimerLabel.text = String.num(timer.time_left, 2)

func _on_flower_grabbed():
	if finished:
		return
	flowers_grabbed += 1
	if goal_type == GOAL_GRAB_FLOWERS and flowers_grabbed == total_flowers:
		finished = true
		%Win.show()

func _on_goal_reached():
	if finished:
		return
	if goal_type == GOAL_REACH_BLOCK:
		finished = true
		%Win.show()

func _on_timer_timeout():
	if finished:
		return
	finished = true
	%GameOver.show()
