class_name Mine

extends Node2D

@export var damage: int = 20
@export var explosion: PackedScene = preload("res://_explosions/explosion1.tscn")

@onready var area: Area2D = $Area2D
@onready var collider: CollisionShape2D = $Area2D/CollisionShape2D

var exploded := false


func _ready():
	area.area_entered.connect(_on_area_entered)


func _on_area_entered(body: Area2D):
	if exploded or not body.is_in_group("Enemies"):
		return

	var enemy = body.get_parent()
	if enemy is Enemy and not enemy.dying:
		enemy.handle_damage(area, damage)
		explode()


func explode():
	if exploded:
		return

	exploded = true
	collider.set_deferred("disabled", true)
	visible = false
	GameManager.shake_camera(3, 5)

	if explosion != null:
		var explosion_instance = explosion.instantiate()
		explosion_instance.global_transform = global_transform
		explosion_instance.scale *= 0.5
		get_tree().root.call_deferred("add_child", explosion_instance)

	queue_free()
