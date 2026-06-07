# ScoreManager.gd
# Manages score, graze count, power level, lives, and bombs
extends Node

signal score_updated(score: int)
signal graze_updated(count: int)
signal power_updated(power: float)
signal lives_updated(lives: int)
signal bombs_updated(bombs: int)
signal power_level_changed(level: int)

const MAX_POWER: float = 4.00
const INITIAL_LIVES: int = 3
const INITIAL_BOMBS: int = 3
const BOMB_PIECES_FOR_BOMB: int = 3

var score: int = 0
var graze_count: int = 0
var power: float = 1.00
var lives: int = INITIAL_LIVES
var bombs: int = INITIAL_BOMBS
var bomb_pieces: int = 0
var spell_bonus: int = 0
var high_score: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_high_score()

func reset_run() -> void:
	score = 0
	graze_count = 0
	power = 1.00
	lives = INITIAL_LIVES
	bombs = INITIAL_BOMBS
	bomb_pieces = 0
	spell_bonus = 0
	_emit_all()

func add_score(amount: int) -> void:
	score += amount
	score_updated.emit(score)

func add_graze() -> void:
	graze_count += 1
	add_score(500)  # Base graze score
	graze_updated.emit(graze_count)

func add_power(amount: float) -> void:
	var old_level := get_power_level()
	power = clamp(power + amount, 0.0, MAX_POWER)
	power_updated.emit(power)
	if get_power_level() != old_level:
		power_level_changed.emit(get_power_level())

func get_power_level() -> int:
	# Returns discrete power level 0-8 (each representing 0.50 power)
	if power < 0.50: return 0
	if power < 1.00: return 1
	if power < 1.50: return 2
	if power < 2.00: return 3
	if power < 2.50: return 4
	if power < 3.00: return 5
	if power < 3.50: return 6
	if power < 4.00: return 7
	return 8

func use_bomb() -> bool:
	if bombs <= 0:
		return false
	bombs -= 1
	bombs_updated.emit(bombs)
	return true

func collect_bomb_piece() -> void:
	bomb_pieces += 1
	if bomb_pieces >= BOMB_PIECES_FOR_BOMB:
		bomb_pieces = 0
		bombs = min(bombs + 1, 8)  # Cap at 8 bombs
		bombs_updated.emit(bombs)

func lose_life() -> int:
	lives -= 1
	lives_updated.emit(lives)
	# Power penalty on death (Touhou: lose ~1.00 power)
	power = max(power - 1.00, 0.0)
	power_updated.emit(power)
	return lives

func on_spell_capture(bonus: int) -> void:
	spell_bonus += bonus
	add_score(bonus)

func get_score_display() -> String:
	return str(score).pad_zeros(10)

func get_graze_display() -> String:
	return str(graze_count).pad_zeros(6)

func _save_high_score() -> void:
	if score > high_score:
		high_score = score
		var file := FileAccess.open("user://highscore.dat", FileAccess.WRITE)
		if file:
			file.store_32(high_score)
			file.close()

func _load_high_score() -> void:
	if FileAccess.file_exists("user://highscore.dat"):
		var file := FileAccess.open("user://highscore.dat", FileAccess.READ)
		if file:
			high_score = file.get_32()
			file.close()

func _emit_all() -> void:
	score_updated.emit(score)
	graze_updated.emit(graze_count)
	power_updated.emit(power)
	lives_updated.emit(lives)
	bombs_updated.emit(bombs)
