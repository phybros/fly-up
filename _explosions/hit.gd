extends Node2D


func _ready():
	await get_tree().create_timer(0.2).timeout
	queue_free()
