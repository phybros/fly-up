class_name Enemy

extends Node2D

const FLASH_SHADER = preload("res://flash.gdshader")

@onready var area: Area2D = $Area2D
@onready var collider: CollisionShape2D = $Area2D/CollisionShape2D
@onready var sprite: Sprite2D = $Sprite

@export var health: int = 100
@export var score: int = 100
@export var explosions: Array[PackedScene] = []
var energy_scene = "res://pickup_energy.tscn"
var energy_loaded: PackedScene

var flash_duration = 0.05  # Duration of the flash in seconds
var flash_material: ShaderMaterial
var flash_tween: Tween

var dying = false

var hit_sound: Resource
var explosion_sound: Resource


# Called when the node enters the scene tree for the first time.
func _ready():
	hit_sound = load("res://_sfx/hit.mp3")

	var sounds = ["res://_sfx/explosion1.mp3", "res://_sfx/explosion2.mp3", "res://_sfx/explosion3.mp3"]
	explosion_sound = load(sounds.pick_random())

	flash_material = ShaderMaterial.new()
	flash_material.shader = FLASH_SHADER
	sprite.material = flash_material

	energy_loaded = load(energy_scene)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if dying:
		return

	for body in area.get_overlapping_areas():
		if body.is_in_group("Bullets"):
			handle_damage(body, body.get_parent().damage)
			body.get_parent().queue_free()
		if body.is_in_group("Beams"):
			handle_damage(body, 5)

	if position.y > 128 or position.y < -128 or position.x > 64 or position.x < -64:
		GameManager.remove_enemy(self)
		queue_free()

	if health <= 0:
		die()


func handle_damage(body, damage):
	GameManager.shake_camera(1, 5)
	health -= damage
	flash()

	#var a = AudioStreamPlayer.new()
	#a.stream = hit_sound
	#a.autoplay = true
	#a.volume_db = -20
	#get_tree().root.call_deferred("add_child", a)
	#await get_tree().create_timer(1).timeout
	#a.queue_free()


func flash():
	if flash_tween and flash_tween.is_valid():
		flash_tween.kill()

	flash_material.set_shader_parameter("flash_amount", 1.0)
	flash_tween = create_tween()
	flash_tween.tween_property(flash_material, "shader_parameter/flash_amount", 0.0, flash_duration)


func die():
	dying = true
	var num_energy_balls = score / 20
	if num_energy_balls <= 0:
		num_energy_balls = 1

	for i in range(num_energy_balls):
		var e = energy_loaded.instantiate()
		e.transform = global_transform
		get_parent().call_deferred("add_child", e)
	collider.disabled = true
	sprite.visible = false
	GameManager.remove_enemy(self)
	GameManager.add_score(score)
	GameManager.shake_camera(5, 10)

	GameManager.play_sound(explosion_sound)

	if randf() > 0.95:
		var l: PackedScene = load("res://powerup.tscn")
		var li = l.instantiate()
		li.global_position = global_position
		get_parent().call_deferred("add_child", li)

	queue_free()


func spawn_explosion(size: float = 1.0):
	if explosions.size() < 1:
		return

	var explosion_scene: PackedScene = explosions.pick_random()
	var explosion = explosion_scene.instantiate()
	explosion.transform = global_transform
	explosion.scale *= size
	get_tree().root.call_deferred("add_child", explosion)
