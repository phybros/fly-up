extends Node2D

@export var speed: int = 10


# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if GameManager.is_game_over:
		speed = 0

	position.y += speed * delta

	if position.y >= 256:
		position.y = 0
