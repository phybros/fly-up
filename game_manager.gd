extends Node

@export var health: int = 100
@export var score: int = 0
@export var energy: int = 0
@export var shield_charge: int = 0
@export var can_boost = false
@export var boosting = false

signal shield_charge_changed(charge: int)
signal energy_changed(energy: int)
signal health_changed(health: int)
signal score_changed(score: int)
signal enemy_died(enemy: Enemy)
signal camera_shake(strength: float, fade: float)
signal game_over
signal restart
signal super_weapon_changed(ready: bool)

var weapons = ["basic", "triple", "triple_wide", "beam", "mega_beam"]
var weapon_titles = ["Standard", "3SHOT", "3SHOT+", "Standard Beam", "MEGA BEAM"]
var current_weapon = 0
var player: Node2D

const SUPER_WEAPON_ENERGY := 5000

var phase = 1

var energy_sound: Resource
var is_game_over = false
var since_last_energy: float = 0.0
var super_weapon_ready = false


func _ready():
	energy_sound = load("res://_sfx/energy.mp3")


func remove_enemy(enemy: Enemy):
	emit_signal("enemy_died", enemy)


func add_score(amount: int):
	score += amount * phase

	if score >= 5000:
		can_boost = true

	emit_signal("score_changed", score)


func add_shield_charge(amount: int):
	shield_charge += amount
	shield_charge = clampi(shield_charge, 0, 100)
	shield_charge_changed.emit(shield_charge)


func set_shield_charge(amount: int):
	shield_charge = amount
	shield_charge = clampi(shield_charge, 0, 100)
	shield_charge_changed.emit(shield_charge)


func _process(delta):
	since_last_energy += delta


func add_energy(amount: int):
	var previous_energy = energy
	var was_ready = super_weapon_ready
	energy = clampi(energy + amount, 0, SUPER_WEAPON_ENERGY)
	super_weapon_ready = energy >= SUPER_WEAPON_ENERGY
	since_last_energy = 0

	if energy != previous_energy:
		emit_signal("energy_changed", energy)

	if was_ready != super_weapon_ready:
		super_weapon_changed.emit(super_weapon_ready)

	if amount <= 0 or energy <= previous_energy:
		return

	var a = AudioStreamPlayer.new()
	a.bus = "SFX (Reverb)"
	a.stream = energy_sound
	a.pitch_scale += randf_range(0, 1)
	a.volume_db = -9
	a.autoplay = true
	get_tree().root.call_deferred("add_child", a)
	await get_tree().create_timer(0.5).timeout
	a.queue_free()


func spend_super_weapon_energy() -> bool:
	if not super_weapon_ready:
		return false

	energy = 0
	super_weapon_ready = false
	since_last_energy = 0
	energy_changed.emit(energy)
	super_weapon_changed.emit(super_weapon_ready)
	return true


func add_health(amount: int):
	health += amount
	emit_signal("health_changed", health)


func shake_camera(strength: float, fade: float):
	emit_signal("camera_shake", strength, fade)


func boost():
	if score >= 5000:
		boosting = true
		score -= 5000
		can_boost = score >= 5000
		await get_tree().create_timer(10).timeout
		boosting = false
		emit_signal("score_changed", score)


func play_sound(sound: Resource):
	var a = AudioStreamPlayer.new()

	a.bus = "SFX"
	a.stream = sound
	a.autoplay = true
	get_tree().root.call_deferred("add_child", a)
	await get_tree().create_timer(1).timeout
	a.queue_free()


func do_game_over():
	is_game_over = true
	game_over.emit()
	print("Game Over")


func do_restart():
	health = 100
	score = 0
	energy = 0
	super_weapon_ready = false
	can_boost = false
	boosting = false
	current_weapon = 0
	phase = 1
	restart.emit()


func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			if Engine.time_scale == 0:
				Engine.time_scale = 1
			else:
				Engine.time_scale = 0
