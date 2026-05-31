extends Node2D
var max_speed = 500
var speed = 0

var target: Node2D
var target_pos: Vector2
var dir: Vector2
var added = false


# Called when the node enters the scene tree for the first time.
func _ready():
	# first, skid to a halt in a circle around the spawn

	dir = Vector2.from_angle(deg_to_rad(randf_range(0, 360)))
	var tween1: Tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	speed = randi_range(75, 200)
	tween1.tween_property(self, "speed", 20, 0.5)
	#tween1.connect("finished", _on_first_tween_finished)

	await get_tree().create_timer(0.4).timeout
	tween1.stop()
	target = GameManager.player
	var t = get_tree().create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(self, "speed", randi_range(500, 1000), randf_range(0.2, 0.8))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if target != null:
		target_pos = target.position
		if position.distance_to(target_pos) < 3.0:
			if !added:
				added = true
				GameManager.add_energy(10)
				queue_free()

		position = position.move_toward(target_pos, speed * delta)
	else:
		position += dir * speed * delta

#func _on_first_tween_finished():
#target = GameManager.player
#var t = get_tree().create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
#t.tween_property(self, "speed", randi_range(500, 1000), randf_range(0.2, 0.8))
