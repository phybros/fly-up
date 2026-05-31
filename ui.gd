extends CanvasLayer

@onready var score_label: Label = $Score
@onready var energy_bar: TextureProgressBar = %EnergyBar
@onready var health_bar: TextureProgressBar = %HealthBar
@onready var super_label: Label = $Weapon
@onready var shield_bar: TextureProgressBar = %ShieldBar
@onready var game_over_menu = $Gameover
@onready var super_button: Button = $Button

const ENERGY_COLOR := Color(0, 0.882353, 0, 1)
const SUPER_READY_COLOR := Color(1, 0.85, 0.1, 1)


# Called when the node enters the scene tree for the first time.
func _ready():
	GameManager.connect("game_over", _on_game_over)

	GameManager.connect("score_changed", _on_score_changed)
	GameManager.connect("health_changed", _on_health_changed)
	GameManager.connect("energy_changed", _on_energy_changed)
	GameManager.connect("shield_charge_changed", _on_shield_charge_changed)
	GameManager.connect("super_weapon_changed", _on_super_weapon_changed)

	energy_bar.max_value = GameManager.SUPER_WEAPON_ENERGY
	super_button.visible = GameManager.super_weapon_ready
	super_label.visible = GameManager.super_weapon_ready
	_on_super_weapon_changed(GameManager.super_weapon_ready)

	GameManager.add_health(0)
	GameManager.add_score(0)
	_on_energy_changed(GameManager.energy)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_score_changed(score: int):
	#scoreLabel.text = str(score)
	score_label.update_val(score)


func _on_health_changed(health: int):
	health_bar.scale *= 1.1

	var t2: Tween = get_tree().create_tween()
	t2.set_ease(Tween.EASE_OUT)
	t2.set_trans(Tween.TRANS_CUBIC)
	t2.tween_property(health_bar, "scale", Vector2.ONE, 0.3)

	var t: Tween = get_tree().create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_CUBIC)
	t.tween_property(health_bar, "value", health, 0.5)


func _on_energy_changed(energy: int):
	energy_bar.max_value = GameManager.SUPER_WEAPON_ENERGY

	energy_bar.scale = Vector2(1.2, 1.2)

	var t2: Tween = get_tree().create_tween()
	t2.set_ease(Tween.EASE_IN)
	t2.set_trans(Tween.TRANS_CUBIC)
	t2.tween_property(energy_bar, "scale", Vector2.ONE, 0.05)

	var t: Tween = get_tree().create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_CUBIC)
	t.tween_property(energy_bar, "value", energy, 0.1)


func _on_shield_charge_changed(charge: int):
	var t: Tween = get_tree().create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_CUBIC)
	t.tween_property(shield_bar, "value", charge, 0.1)

	if charge == 100:
		shield_bar.scale *= 1.1

		var t2: Tween = get_tree().create_tween()
		t2.set_ease(Tween.EASE_OUT)
		t2.set_trans(Tween.TRANS_CUBIC)
		t2.tween_property(shield_bar, "scale", Vector2.ONE, 0.3)


func _on_game_over():
	game_over_menu.visible = true
	game_over_menu.find_child("Restart Button", true).connect("pressed", _on_restart)


func _on_restart():
	game_over_menu.visible = false
	GameManager.is_game_over = false
	GameManager.do_restart()


func _on_super_weapon_changed(ready: bool):
	super_button.visible = ready
	super_label.visible = ready
	super_label.text = "SUPER READY"
	energy_bar.tint_progress = SUPER_READY_COLOR if ready else ENERGY_COLOR

	if not ready:
		return

	super_label.scale = Vector2(1.2, 1.2)
	var t: Tween = get_tree().create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.set_trans(Tween.TRANS_CUBIC)
	t.tween_property(super_label, "scale", Vector2.ONE, 0.2)
