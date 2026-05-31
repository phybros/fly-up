extends Enemy

class_name Asteroid

@export var spin_rate: float = 10.0
@export var explode_into: PackedScene
@export var explode_into_min: int = 0
@export var explode_into_max: int = 0
@export var initial_move_vector: Vector2 = Vector2.ZERO

signal asteroid_died(asteroid: Asteroid)

var speed := 40


# Called when the node enters the scene tree for the first time.
func _ready():
	super._ready()

	var move_tween = get_tree().create_tween()
	move_tween.tween_property(self, "initial_move_vector", Vector2.ZERO, 3).set_ease(Tween.EASE_OUT)

	var rotation_tween = get_tree().create_tween()
	rotation_tween.tween_property(self, "spin_rate", sign(spin_rate) * 50, 5)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if GameManager.is_game_over:
		speed = 0

	if dying:
		return

	position.y += speed * delta

	if not dying:
		rotation_degrees += spin_rate * delta
		position += initial_move_vector * delta

	super._process(delta)

	if position.x > 64 or position.x < -64:
		asteroid_died.emit(self)
		queue_free()

	#if position.y > 150:
	#asteroid_died.emit(self)
	#queue_free()


func die():
	dying = true
	spin_rate = 0

	super.spawn_explosion()

	if explode_into != null:
		var num_chunks = randi_range(explode_into_min, explode_into_max)

		for i in range(num_chunks):
			var new_chunk = explode_into.instantiate()
			new_chunk.transform = global_transform
			new_chunk.position = position
			new_chunk.spin_rate *= randf_range(-10.0, 10.0)
			new_chunk.speed = 0
			new_chunk.initial_move_vector = Vector2(randf_range(-50, 50), randf_range(-50, 50))
			get_parent().call_deferred("add_child", new_chunk)

	asteroid_died.emit(self)
	super.die()


func _on_visible_on_screen_notifier_2d_screen_exited():
	asteroid_died.emit(self)
	queue_free()
