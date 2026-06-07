# GameManager.gd
# Global game controller — manages game state, player spawning, transitions
extends Node

signal game_state_changed(old_state: int, new_state: int)
signal player_died()
signal player_respawned()
signal stage_started(stage_num: int)
signal stage_cleared(stage_num: int)
signal boss_spawned()
signal boss_defeated()
signal game_over()

enum State { TITLE, PLAYING, PAUSED, STAGE_CLEAR, GAME_OVER }

var current_state: int = State.TITLE
var current_stage: int = 1
var continues_used: int = 0
var max_continues: int = 3
var player_node: Node2D = null
var game_scene: Node = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(_delta: float) -> void:
	# Handle pause toggle
	if Input.is_action_just_pressed("pause"):
		if current_state == State.PLAYING:
			pause_game()
		elif current_state == State.PAUSED:
			unpause_game()

func change_state(new_state: int) -> void:
	var old_state = current_state
	current_state = new_state
	game_state_changed.emit(old_state, new_state)

func start_game(stage_num: int = 1) -> void:
	current_stage = stage_num
	continues_used = 0
	change_state(State.PLAYING)
	stage_started.emit(stage_num)

func get_player() -> Node2D:
	return player_node

func register_player(player: Node2D) -> void:
	player_node = player

func on_player_death() -> void:
	player_died.emit()
	# Check for game over vs continue
	if ScoreManager.lives <= 0:
		if continues_used < max_continues:
			# Allow continue
			pass
		else:
			trigger_game_over()

func continue_game() -> void:
	continues_used += 1
	ScoreManager.lives = 3
	ScoreManager.bombs = 3
	ScoreManager.power = 0.0
	change_state(State.PLAYING)

func on_stage_clear() -> void:
	change_state(State.STAGE_CLEAR)
	stage_cleared.emit(current_stage)

func trigger_game_over() -> void:
	change_state(State.GAME_OVER)
	game_over.emit()

func pause_game() -> void:
	change_state(State.PAUSED)
	get_tree().paused = true

func unpause_game() -> void:
	get_tree().paused = false
	change_state(State.PLAYING)

func quit_to_title() -> void:
	get_tree().paused = false
	change_state(State.TITLE)
