extends Node2D

@export var projectiles: Array[PackedScene]
@export var explosion: PackedScene
@export var bullet: PackedScene
@export var mine: PackedScene = preload("res://_projectiles/mine.tscn")
@export var speed = 300  # Maximum speed in pixels per second
@export var acceleration = 2000  # How quickly the node accelerates

@onready var shield: AnimatedSprite2D = $Shield
var shield_active := false

@onready var anim = $"Sprite Base"
@onready var shoot_timer = $"Shoot Timer"
@onready var area: Area2D = $Area2D
@onready var collider: CollisionShape2D = $Area2D/CollisionShape2D
@onready var beam_area = $"Beam Area"
@onready var beam_collider = $"Beam Area/Beam Collider"
var beam_firing = false

var velocity = Vector2.ZERO  # Current velocity

const WEAPON_THREE_SHOT := 2
const WEAPON_PLASMA := 4
const MINE_COUNT := 5
const MINE_ORBIT_RADIUS := 20.0
const MINE_ORBIT_SPEED := 2.5

const BULLET_POOL_SIZE = 5  # Number of bullets in the pool
var available_projectiles: Array[Projectile] = []  # Stack of available bullets for reuse
var invincible = false
var mine_orbit: Node2D

@onready var afterburner_l = $Afterburners
@onready var afterburner_r = $Afterburners2
var afterburner_l_pos: Vector2
var afterburner_r_pos: Vector2

signal weapon_changed(weapon_name: String)

var finger_down_point: Vector2

var dying := false

var explosion_sounds: Array[Resource]
var hit_sound: Resource


# Called when the node enters the scene tree for the first time.
func _ready():
	var s = ["res://_sfx/explosion1.mp3", "res://_sfx/explosion2.mp3", "res://_sfx/explosion3.mp3"]
	for so in s:
		explosion_sounds.append(load(so))
	hit_sound = load("res://_sfx/hit.mp3")

	beam_collider.disabled = true

	afterburner_l_pos = afterburner_l.position
	afterburner_r_pos = afterburner_r.position
	GameManager.player = self


func weapon_up():
	if GameManager.current_weapon + 1 > GameManager.weapons.size() - 1:
		GameManager.current_weapon = 0
	else:
		GameManager.current_weapon += 1


func weapon_down():
	if GameManager.current_weapon - 1 < 0:
		GameManager.current_weapon = GameManager.weapons.size() - 1
	else:
		GameManager.current_weapon -= 1


func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				finger_down_point = event.position
			else:
				finger_down_point = Vector2.ZERO


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if dying:
		return

	if mine_orbit != null and is_instance_valid(mine_orbit):
		mine_orbit.rotation += MINE_ORBIT_SPEED * delta

	var target_velocity = Vector2.ZERO  # Target velocity

	afterburner_l.position = afterburner_l_pos
	afterburner_r.position = afterburner_r_pos
	anim.frame = 0

	if Input.is_key_pressed(KEY_0):
		activate_shield()
	if Input.is_key_pressed(KEY_1):
		deactivate_shield()

	if Input.is_action_just_pressed("weapon_up"):
		weapon_up()
	if Input.is_action_just_pressed("weapon_down"):
		weapon_down()

	#if finger_down_point == Vector2.ZERO and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
	#finger_down_point = get_global_mouse_position()
	#print(finger_down_point)
#
	#if !Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
	#finger_down_point = Vector2.ZERO

	var input_vector = get_input_vector()
	var current_pos = get_global_mouse_position() + Vector2(0, -20)

	if finger_down_point != Vector2.ZERO:
		#so much jank
		if Vector2(current_pos.x, 0).distance_to(Vector2(position.x, 0)) > 5:
			input_vector += Vector2(current_pos.x, 0) - Vector2(position.x, 0)
			target_velocity += speed * input_vector.clampf(-1.0, 1.0)
		if Vector2(0, current_pos.y).distance_to(Vector2(0, position.y)) > 5:
			input_vector += Vector2(0, current_pos.y) - Vector2(0, position.y)
			target_velocity += speed * input_vector.clampf(-1.0, 1.0)
		#if current_pos.distance_to(position) > 10:
		#input_vector = current_pos - position
		#target_velocity += speed * input_vector.clampf(-1.0, 1.0)
	else:
		# Determine the target velocity based on input
		if input_vector.x < 0:
			if position.x > -42:
				anim.frame = 1
				afterburner_r.position.x -= 1
				target_velocity.x -= speed
		if input_vector.x > 0:
			if position.x < 42:
				afterburner_l.position.x += 1
				anim.frame = 2
				target_velocity.x += speed
		if input_vector.y < 0:
			if position.y > -90:
				target_velocity.y -= speed
		if input_vector.y > 0:
			if position.y < 90:
				target_velocity.y += speed

	if Input.is_action_just_pressed("ui_accept"):
		if GameManager.super_weapon_ready:
			fire_super_weapon()
		#elif GameManager.can_boost:
		#GameManager.boost()

	# Smoothly interpolate the velocity toward the target velocity
	velocity = velocity.lerp(target_velocity, acceleration * delta / speed)

	var change = velocity * delta
	#if (position + change).x > -180 && (position + change).x < 180:

	position += change

	#if target_velocity.x != 0:
	#sprite.scale.x = 0.45
	#else:
	#sprite.scale.x = 0.5

	if GameManager.boosting:
		shoot_timer.wait_time = 0.05
	else:
		shoot_timer.wait_time = 0.2

	for body in area.get_overlapping_areas():
		if body.is_in_group("Enemies") and not invincible:
			do_collision(body)
		if body.is_in_group("Enemy Projectiles") and not invincible:
			do_collision(body)
			body.get_parent().queue_free()


func do_collision(with: Area2D):
	# start I frames
	collider.disabled = true
	invincible = true

	GameManager.play_sound(hit_sound)

	if shield_active:
		take_shield_damage(with)
	else:
		# shake the camera
		# take damage
		take_damage(with)


func take_shield_damage(from: Area2D):
	GameManager.shake_camera(2, 5)
	GameManager.add_shield_charge(-100)
	deactivate_shield()
	await get_tree().create_timer(1).timeout
	invincible = false
	collider.disabled = false


func take_damage(from: Area2D):
	GameManager.set_shield_charge(0)

	GameManager.shake_camera(10, 5)
	GameManager.add_health(-20)

	if GameManager.health <= 0:
		die()
		return

	for i in range(0, 10):
		self.visible = false
		await get_tree().create_timer(0.05).timeout
		self.visible = true
		await get_tree().create_timer(0.05).timeout
		if i >= 9:
			invincible = false
			collider.disabled = false


func get_input_vector():
	var input = Vector2.ZERO

	if Input.is_action_pressed("move_left"):
		input += Vector2(-1, 0)
	if Input.is_action_pressed("move_right"):
		input += Vector2(1, 0)
	if Input.is_action_pressed("move_up"):
		input += Vector2(0, -1)
	if Input.is_action_pressed("move_down"):
		input += Vector2(0, 1)

	return input


func _on_shoot_timer_timeout():
	if dying:
		return

	fire_weapon_basic(GameManager.current_weapon)


func die():
	dying = true
	visible = false

	for i in range(30):
		GameManager.play_sound(explosion_sounds.pick_random())
		var ex: Node2D = explosion.instantiate()
		ex.transform = global_transform
		var sc = randf_range(1.0, 3.0)
		ex.scale = Vector2(sc, sc)
		var po = randf_range(-10, 10)
		ex.position += Vector2(po, po)
		get_tree().root.call_deferred("add_child", ex)
		await get_tree().create_timer(0.1).timeout
	queue_free()
	GameManager.do_game_over()


func fire_weapon_basic(projectile_index: int = 0):
	if projectile_index < 0 or projectile_index >= projectiles.size():
		return

	var b: Projectile = projectiles[projectile_index].instantiate()
	b.transform = global_transform
	b.position = position + Vector2(0, -10)
	get_parent().call_deferred("add_child", b)


func fire_super_weapon():
	if beam_firing or not GameManager.spend_super_weapon_energy():
		return

	beam_firing = true
	beam_collider.disabled = false
	beam_area.visible = true

	for i in range(120):
		GameManager.shake_camera(2, 20)
		beam_area.visible = true
		beam_area.scale.x = randf_range(0.85, 1.15)
		await get_tree().create_timer(0.04).timeout
		beam_area.visible = false
		await get_tree().create_timer(0.01).timeout

	beam_area.scale = Vector2.ONE
	beam_collider.disabled = true
	beam_area.visible = false
	beam_firing = false


func activate_mines():
	if mine == null:
		return

	if mine_orbit == null or not is_instance_valid(mine_orbit):
		mine_orbit = Node2D.new()
		mine_orbit.name = "Mine Orbit"
		add_child(mine_orbit)

	for child in mine_orbit.get_children():
		mine_orbit.remove_child(child)
		child.queue_free()

	mine_orbit.rotation = 0.0
	for i in range(MINE_COUNT):
		var new_mine = mine.instantiate()
		var angle = TAU * float(i) / float(MINE_COUNT)
		new_mine.position = Vector2.RIGHT.rotated(angle) * MINE_ORBIT_RADIUS
		mine_orbit.add_child(new_mine)


func activate_3shot():
	set_weapon(WEAPON_THREE_SHOT)


func activate_plasma():
	set_weapon(WEAPON_PLASMA)


func set_weapon(projectile_index: int):
	if projectile_index < 0 or projectile_index >= projectiles.size():
		return

	GameManager.current_weapon = projectile_index
	if projectile_index < GameManager.weapons.size():
		weapon_changed.emit(GameManager.weapons[projectile_index])
	else:
		weapon_changed.emit(str(projectile_index))


#
#func recycle_bullet(b):
## Return the bullet to the pool
#available_projectiles.append(b)


func activate_shield():
	shield.visible = true
	shield.play()


func deactivate_shield():
	shield.play_backwards()


func shield_animation_finished():
	if shield.frame == 0:
		# shield deactivated
		shield_active = false
		shield.visible = false
		collider.shape.radius = 4
		GameManager.set_shield_charge(0)
	else:
		# shield activated
		shield_active = true
		shield.visible = true
		collider.shape.radius = 9


func _on_shield_recharge_timeout():
	if dying:
		return
	GameManager.add_shield_charge(100)
	activate_shield()
