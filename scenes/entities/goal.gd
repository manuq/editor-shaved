class_name Goal extends Area2D

signal goal_reached


func _on_body_entered(body):
	goal_reached.emit()
