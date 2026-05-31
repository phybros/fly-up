extends Node2D

@onready var area: Area2D = $"Collision Area"
@onready var collider: CollisionShape2D = $"Collision Area/Collider"

var speed: float = 60.0


# Called when the node enters the scene tree for the first time.
func _ready():
	var original_speed = speed
	speed *= 5

	var speed_tween = get_tree().create_tween()
	speed_tween.set_ease(Tween.EASE_OUT)
	speed_tween.set_trans(Tween.TRANS_CUBIC)
	speed_tween.tween_property(self, "speed", original_speed, 0.6)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if position.y > 128 or position.y < -128 or position.x > 64 or position.x < -64:
		queue_free()

	position.y += speed * delta
