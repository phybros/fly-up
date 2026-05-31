extends Node2D

var effects: Array[StringName] = [
	&"shield",
	&"mines",
	&"plasma",
	&"3shot",
	&"armor",
]
var effect: StringName = &""
var collected := false

@onready var area: Area2D = $Area2D


func _ready():
	area.area_entered.connect(_on_area_entered)
	effect = effects.pick_random()

	match effect:
		&"shield":
			%Shield.visible = true
		&"mines":
			%Mines.visible = true
		&"3shot":
			%"3Shot".visible = true
		&"plasma":
			%Plasma3.visible = true
		&"armor":
			%Armor.visible = true


func _process(delta):
	position += Vector2(0, 20 * delta)

	for body in area.get_overlapping_areas():
		if body.is_in_group("Player"):
			collect(body)
			return


func _on_area_entered(body: Area2D):
	if body.is_in_group("Player"):
		collect(body)


func collect(body: Area2D):
	if collected:
		return

	collected = true
	var player = body.get_parent()
	if player == null:
		player = GameManager.player

	match effect:
		&"shield":
			if player.has_method("activate_shield"):
				player.activate_shield()
		&"mines":
			if player.has_method("activate_mines"):
				player.activate_mines()
		&"3shot":
			if player.has_method("activate_3shot"):
				player.activate_3shot()
		&"plasma":
			if player.has_method("activate_plasma"):
				player.activate_plasma()
		&"armor":
			if player.has_method("activate_armor"):
				player.activate_armor()
	queue_free()
