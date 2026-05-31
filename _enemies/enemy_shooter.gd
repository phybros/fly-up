extends Enemy

@export var bullet: PackedScene
@onready var shoot_timer: Timer = $"Shoot Timer"
var move_dir := 1
var speedy = 30
var speedx = 0
@export var horizontal_speed: int = 50
@export var vertical_speed: int = 30


func _ready():
	print("shooter ready")
	shoot_timer.connect("timeout", _shoot)
	super._ready()

	await get_tree().create_timer(2).timeout
	speedy = 0
	speedx = horizontal_speed
	await get_tree().create_timer(7).timeout
	speedy = vertical_speed
	await get_tree().create_timer(2).timeout
	speedy = 0
	await get_tree().create_timer(7).timeout
	speedy = vertical_speed
	await get_tree().create_timer(2).timeout
	speedy = 0
	await get_tree().create_timer(7).timeout
	speedy = vertical_speed


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if GameManager.is_game_over:
		speedx = 0
		speedy = 0
	super._process(delta)

	if position.x >= 60:
		move_dir = -1
	elif position.x <= -60:
		move_dir = 1

	position.y += speedy * delta
	position.x += speedx * move_dir * delta


func _shoot():
	if GameManager.is_game_over:
		return
	var newbullet = bullet.instantiate()
	newbullet.transform = global_transform
	newbullet.position += Vector2(0, 10)
	get_parent().call_deferred("add_child", newbullet)


func die():
	shoot_timer.stop()
	spawn_explosion(2)
	super.die()
