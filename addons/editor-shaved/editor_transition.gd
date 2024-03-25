@tool
extends CanvasLayer

signal half_completed
signal completed

func transition():
		%AnimationPlayer.play("transition_in")
		await %AnimationPlayer.animation_finished
		half_completed.emit()
		%AnimationPlayer.play("transition_out")
		await %AnimationPlayer.animation_finished
		completed.emit()
		queue_free()
