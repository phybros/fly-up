extends Node2D

const EnemyWaveEntry = preload("res://enemy_wave_entry.gd")

const SPAWN_X_MIN := -500
const SPAWN_X_MAX := 500
const WORLD_X_MIN := -45
const WORLD_X_MAX := 45

const DEFAULT_FORMATIONS = [&"scatter", &"column_left", &"column_right", &"pincer"]

const FORMATION_DATA = {
	&"scatter": {"min_phase": 1, "weight": 4.0},
	&"column_left": {"min_phase": 1, "weight": 2.0},
	&"column_right": {"min_phase": 1, "weight": 2.0},
	&"pincer": {"min_phase": 4, "weight": 2.5},
	&"center_stream": {"min_phase": 6, "weight": 1.5},
	&"screen": {"min_phase": 8, "weight": 1.0},
}

const DEFAULT_ENEMY_DATA = {
	"res://_enemies/basic_enemy.tscn":
	{
		"title": "Basic",
		"unlock_phase": 1,
		"cost": 1,
		"weight": 5.0,
		"min_group": 3,
		"max_group": 8,
		"spawn_delay": 0.45,
		"formations": [&"scatter", &"column_left", &"column_right", &"pincer", &"screen"],
	},
	"res://_enemies/enemy_fast.tscn":
	{
		"title": "Fast",
		"unlock_phase": 6,
		"cost": 2,
		"weight": 3.0,
		"min_group": 2,
		"max_group": 6,
		"spawn_delay": 0.2,
		"formations": [&"column_left", &"column_right", &"center_stream", &"pincer"],
	},
	"res://_enemies/enemy_shooter.tscn":
	{
		"title": "Shooter",
		"unlock_phase": 3,
		"cost": 5,
		"weight": 1.5,
		"min_group": 1,
		"max_group": 2,
		"spawn_delay": 1.5,
		"formations": [&"scatter", &"screen"],
	},
}

@onready var spawn_timer: Timer = $"Spawn Timer"

@export var asteroids: Array[PackedScene] = []
@export var enemies: Array[PackedScene] = []
@export var enemy_roster: Array[EnemyWaveEntry] = []
@export var asteroid_timer := 0

@export_group("Wave Tuning")
@export var first_phase := 1
@export var base_phase_budget := 6
@export var budget_growth := 1.35
@export var max_phase_budget := 60
@export var max_groups_per_phase := 6
@export var group_pause_min := 0.2
@export var group_pause_max := 1.0

var active_enemies: Array[Enemy] = []
var active_asteroids: Array[Asteroid] = []
var wave_roster: Array[EnemyWaveEntry] = []
var is_spawning_phase := false


func _ready():
	randomize()
	wave_roster = _build_wave_roster()

	GameManager.phase = first_phase
	if not GameManager.enemy_died.is_connected(_on_enemy_died):
		GameManager.enemy_died.connect(_on_enemy_died)
	begin_phase(GameManager.phase)


func _on_enemy_died(enemy: Enemy):
	active_enemies.erase(enemy)
	_advance_when_phase_is_clear()


func begin_phase(newphase: int):
	if GameManager.is_game_over:
		return

	print("New Phase " + str(newphase))
	is_spawning_phase = true

	var wave_plan := _build_wave_plan(newphase)
	for group in wave_plan:
		if GameManager.is_game_over:
			break

		await _spawn_wave_group(group)

		var pause: float = group.get("pause", 0.0)
		if pause > 0.0 and not GameManager.is_game_over:
			await get_tree().create_timer(pause).timeout

	is_spawning_phase = false
	_advance_when_phase_is_clear()


func spawn_enemy(enemy: PackedScene, num: int = 1, minx: int = SPAWN_X_MIN, maxx: int = SPAWN_X_MAX, delay: float = 0.6):
	for i in range(num):
		_spawn_enemy_at(enemy, randi_range(minx, maxx))

		if delay > 0.0 and i < num - 1:
			await get_tree().create_timer(delay).timeout


func spawn_asteroid():
	if asteroids.is_empty():
		return

	var randomscale = randf_range(-0.2, 0.75)
	var newasteroid: Node2D = asteroids[randi_range(0, asteroids.size() - 1)].instantiate()
	newasteroid.transform = global_transform
	newasteroid.position = position + Vector2(randi_range(-60, 60), -128)
	newasteroid.scale += Vector2(randomscale, randomscale)
	newasteroid.connect("asteroid_died", _on_asteroid_died)
	call_deferred("add_child", newasteroid)
	active_asteroids.append(newasteroid)


func _build_wave_roster() -> Array[EnemyWaveEntry]:
	var roster: Array[EnemyWaveEntry] = []

	for entry in enemy_roster:
		if entry != null and entry.scene != null:
			roster.append(entry)

	if not roster.is_empty():
		return roster

	for scene in enemies:
		if scene != null:
			roster.append(_entry_from_scene(scene))

	if roster.is_empty():
		for scene_path in DEFAULT_ENEMY_DATA.keys():
			var scene: PackedScene = load(scene_path)
			if scene != null:
				roster.append(_entry_from_scene(scene))

	return roster


func _entry_from_scene(scene: PackedScene) -> EnemyWaveEntry:
	var entry := EnemyWaveEntry.new()
	var scene_path := scene.resource_path
	var defaults: Dictionary = DEFAULT_ENEMY_DATA.get(scene_path, {})

	entry.scene = scene
	entry.title = defaults.get("title", scene_path.get_file().get_basename())
	entry.unlock_phase = defaults.get("unlock_phase", 1 + enemies.find(scene) * 2)
	entry.cost = defaults.get("cost", 2)
	entry.weight = defaults.get("weight", 1.0)
	entry.min_group = defaults.get("min_group", 1)
	entry.max_group = defaults.get("max_group", 4)
	entry.spawn_delay = defaults.get("spawn_delay", 0.6)

	var formations: Array = defaults.get("formations", DEFAULT_FORMATIONS)
	for formation in formations:
		entry.formations.append(formation)

	return entry


func _build_wave_plan(phase: int) -> Array[Dictionary]:
	var budget := _phase_budget(phase)
	var groups: Array[Dictionary] = []
	var max_groups := clampi(2 + int(phase / 4), 2, max_groups_per_phase)

	while budget > 0 and groups.size() < max_groups:
		var enemy_entry := _pick_enemy_entry(phase, budget)
		if enemy_entry == null:
			break

		var group := _make_group(enemy_entry, phase, budget)
		groups.append(group)
		budget -= int(group["count"]) * enemy_entry.cost

	return groups


func _phase_budget(phase: int) -> int:
	var scaled_budget := base_phase_budget + int(floor(pow(float(phase), 1.18) * budget_growth))
	return clampi(scaled_budget, 1, max_phase_budget)


func _pick_enemy_entry(phase: int, budget: int) -> EnemyWaveEntry:
	var candidates: Array[Dictionary] = []
	var total_weight := 0.0

	for entry in wave_roster:
		if phase < entry.unlock_phase or entry.cost > budget:
			continue

		var age: int = max(0, phase - entry.unlock_phase)
		var weight: float = max(0.0, entry.weight + min(age * 0.08, 2.5))
		if weight <= 0.0:
			continue

		candidates.append({"entry": entry, "weight": weight})
		total_weight += weight

	if candidates.is_empty():
		return null

	var roll := randf() * total_weight
	for candidate in candidates:
		roll -= candidate["weight"]
		if roll <= 0.0:
			return candidate["entry"]

	return candidates.back()["entry"]


func _make_group(entry: EnemyWaveEntry, phase: int, budget: int) -> Dictionary:
	var max_affordable: int = max(1, int(floor(float(budget) / float(entry.cost))))
	var min_count := clampi(entry.min_group, 1, max_affordable)
	var max_count := clampi(entry.max_group + int(max(0, phase - entry.unlock_phase) / 10), min_count, max_affordable)
	var count := randi_range(min_count, max_count)
	var formation := _pick_formation(entry, phase)

	if formation == &"screen":
		count = clampi(max(count, 5), min_count, max_affordable)

	return {
		"scene": entry.scene,
		"count": count,
		"formation": formation,
		"lanes": _lanes_for_formation(formation),
		"delay": _delay_for_formation(entry.spawn_delay, formation),
		"pause": randf_range(group_pause_min, group_pause_max),
	}


func _pick_formation(entry: EnemyWaveEntry, phase: int) -> StringName:
	var formations: Array[StringName] = []
	for formation in entry.formations:
		formations.append(formation)
	if formations.is_empty():
		for formation in DEFAULT_FORMATIONS:
			formations.append(formation)

	var candidates: Array[Dictionary] = []
	var total_weight := 0.0

	for formation in formations:
		var data: Dictionary = FORMATION_DATA.get(formation, {})
		if phase < data.get("min_phase", 1):
			continue

		var weight: float = data.get("weight", 1.0)
		candidates.append({"formation": formation, "weight": weight})
		total_weight += weight

	if candidates.is_empty():
		return &"scatter"

	var roll := randf() * total_weight
	for candidate in candidates:
		roll -= candidate["weight"]
		if roll <= 0.0:
			return candidate["formation"]

	return candidates.back()["formation"]


func _lanes_for_formation(formation: StringName) -> Array[Vector2]:
	match formation:
		&"column_left":
			return [Vector2(-500, -300)]
		&"column_right":
			return [Vector2(300, 500)]
		&"pincer":
			return [Vector2(-500, -360), Vector2(360, 500)]
		&"center_stream":
			return [Vector2(0, 0)]
		&"screen":
			return [Vector2(-480, -480), Vector2(-240, -240), Vector2(0, 0), Vector2(240, 240), Vector2(480, 480)]
		_:
			return [Vector2(SPAWN_X_MIN, SPAWN_X_MAX)]


func _delay_for_formation(base_delay: float, formation: StringName) -> float:
	match formation:
		&"pincer", &"center_stream":
			return max(0.08, base_delay * 0.45)
		&"screen":
			return max(0.05, base_delay * 0.25)
		_:
			return max(0.05, base_delay * randf_range(0.8, 1.2))


func _spawn_wave_group(group: Dictionary):
	var lanes: Array[Vector2] = group["lanes"]
	var enemy_scene: PackedScene = group["scene"]
	var count: int = group["count"]
	var delay: float = group["delay"]

	for i in range(count):
		var lane := lanes[i % lanes.size()]
		var spawn_x := int(lane.x)
		if int(lane.x) != int(lane.y):
			spawn_x = randi_range(int(lane.x), int(lane.y))

		_spawn_enemy_at(enemy_scene, spawn_x)

		if delay > 0.0 and i < count - 1:
			await get_tree().create_timer(delay).timeout


func _spawn_enemy_at(enemy_scene: PackedScene, spawn_x: int):
	if enemy_scene == null:
		return

	var newenemy = enemy_scene.instantiate()
	newenemy.transform = global_transform
	newenemy.position = position + Vector2(_to_world_x(spawn_x), -128)

	call_deferred("add_child", newenemy)
	if newenemy is Enemy:
		active_enemies.append(newenemy)
	else:
		push_warning("Spawned scene does not extend Enemy: " + str(enemy_scene.resource_path))


func _to_world_x(spawn_x: int) -> float:
	return remap(spawn_x, SPAWN_X_MIN, SPAWN_X_MAX, WORLD_X_MIN, WORLD_X_MAX)


func _advance_when_phase_is_clear():
	if is_spawning_phase or GameManager.is_game_over:
		return

	if active_enemies.is_empty():
		print("no enemies left on phase " + str(GameManager.phase))
		_on_phase_timer_timeout()


func _on_asteroid_died(asteroid: Asteroid):
	active_asteroids.erase(asteroid)


func _on_spawn_timer_timeout():
	pass


func _on_phase_timer_timeout():
	if GameManager.is_game_over:
		return

	GameManager.phase += 1
	begin_phase(GameManager.phase)


func _on_asteroid_timer_timeout():
	if randf() > 0.4:
		if active_asteroids.size() <= 0:
			spawn_asteroid()
