class_name EnemyWaveEntry
extends Resource

@export var scene: PackedScene
@export var title := ""
@export_range(1, 999) var unlock_phase := 1
@export_range(1, 99) var cost := 1
@export_range(0.0, 100.0, 0.1) var weight := 1.0
@export_range(1, 99) var min_group := 1
@export_range(1, 99) var max_group := 5
@export_range(0.0, 5.0, 0.05) var spawn_delay := 0.6
# Supported names: scatter, column_left, column_right, pincer, center_stream, screen.
@export var formations: Array[StringName] = []
