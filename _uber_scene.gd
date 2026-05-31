extends Node2D

var game_scene: Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	GameManager.connect("restart", _on_restart)
	startup()


func startup():
	game_scene = load("res://main.tscn").instantiate()
	call_deferred("add_child", game_scene)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_restart():
	game_scene.queue_free()
	startup()
