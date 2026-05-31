class_name Projectile

extends Node2D

@export var speed: int = 300
@export var damage: int = 5

var running: bool = false
@onready var area: Area2D = $"Collision Area"
@onready var collider: CollisionShape2D = $"Collision Area/Collider"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass  # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#if running:
	position.y -= speed * delta

	if position.x > 64 or position.x < -64 or position.y > 128 or position.y < -128:
		queue_free()
