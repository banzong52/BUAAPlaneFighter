# WaveController.gd
# Reads stage data resources and spawns enemy waves accordingly
extends Node

signal wave_started(wave_index: int)
signal wave_cleared(wave_index: int)
signal midboss_spawned()
signal boss_warning()
signal boss_spawned()
signal stage_complete()
signal all_waves_cleared()

var current_stage_data: Resource = null
var current_wave_index: int = -1
var stage_elapsed: float = 0.0
var active_enemies: Array[Node] = []
var is_boss_phase: bool = false
var boss_node: Node = null
var is_running: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	if not is_running or GameManager.current_state != GameManager.State.PLAYING:
		return
	stage_elapsed += delta
	_check_wave_triggers()

func load_stage(stage_num: int) -> void:
	current_stage_data = ResourceManager.get_stage_data(stage_num)
	if current_stage_data == null:
		push_error("WaveController: Failed to load stage %d" % stage_num)
		return
	current_wave_index = -1
	stage_elapsed = 0.0
	active_enemies.clear()
	is_boss_phase = false
	boss_node = null

func start_stage() -> void:
	is_running = true

func stop_stage() -> void:
	is_running = false
	# Despawn all remaining enemies
	for enemy in active_enemies:
		if is_instance_valid(enemy) and enemy.has_method("destroy"):
			enemy.destroy()
	active_enemies.clear()

func _check_wave_triggers() -> void:
	if current_stage_data == null:
		return

	var waves: Array = current_stage_data.get("waves") if current_stage_data else []
	for i in range(current_wave_index + 1, waves.size()):
		var wave = waves[i]
		var spawn_time: float = wave.get("spawn_time") if wave is Resource else 0.0
		if stage_elapsed >= spawn_time:
			current_wave_index = i
			_spawn_wave(wave)
			wave_started.emit(i)

func _spawn_wave(wave: Resource) -> void:
	var enemies = wave.get("enemies") if wave else []
	if enemies == null:
		return

	for spawn_entry in enemies:
		if spawn_entry == null:
			continue
		var enemy_id: String = spawn_entry.get("enemy_id") if spawn_entry is Resource else ""
		var spawn_pos: Vector2 = spawn_entry.get("position") if spawn_entry is Resource else Vector2.ZERO
		var delay: float = spawn_entry.get("delay") if spawn_entry is Resource else 0.0

		if delay > 0:
			await get_tree().create_timer(delay).timeout
			if not is_running:
				return

		_spawn_enemy(enemy_id, spawn_pos, spawn_entry)

func _spawn_enemy(enemy_id: String, pos: Vector2, spawn_data: Resource = null) -> void:
	var scene_path := "res://scenes/enemies/%s.tscn" % enemy_id
	if not ResourceLoader.exists(scene_path):
		# Try falling back to fairy
		scene_path = "res://scenes/enemies/fairy.tscn"
		if not ResourceLoader.exists(scene_path):
			return

	var scene := load(scene_path) as PackedScene
	if scene == null:
		return

	var enemy := scene.instantiate()
	if enemy == null:
		return

	enemy.global_position = pos

	var enemy_layer := _get_enemy_layer()
	if enemy_layer:
		enemy_layer.add_child(enemy)

	if enemy.has_method("init") and spawn_data:
		enemy.init(spawn_data)

	active_enemies.append(enemy)

	# Connect death signal
	if enemy.has_signal("destroyed"):
		enemy.destroyed.connect(_on_enemy_destroyed.bind(enemy))

func _on_enemy_destroyed(enemy: Node) -> void:
	active_enemies.erase(enemy)
	if is_boss_phase and enemy == boss_node:
		boss_node = null
		is_boss_phase = false
		boss_defeated()

func boss_defeated() -> void:
	stage_complete.emit()

func get_alive_enemy_count() -> int:
	return active_enemies.size()

func _get_enemy_layer() -> Node2D:
	if GameManager.game_scene:
		var world := GameManager.game_scene.get_node_or_null("World")
		if world:
			return world.get_node_or_null("EnemyLayer")
	return null
