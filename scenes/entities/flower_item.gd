class_name FlowerItem extends Area2D

signal flower_grabbed


func _on_body_entered(body):
	flower_grabbed.emit()
	queue_free()
