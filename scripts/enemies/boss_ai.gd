# BossAI.gd — Boss-specific behavior with spell card phases
extends Node

class_name BossAI

signal spell_card_started(spell_name: String, duration: float)
signal spell_card_ended(captured: bool)

enum BossPhase { SPAWNING, NONSPELL, SPELL_CARD, DYING }

var phase: int = BossPhase.SPAWNING
var phase_timer: float = 0.0
var phase_index: int = 0

# Spell card data
var spell_cards: Array[Dictionary] = []
var current_spell: int = -1
var spell_timer: float = 0.0

# Non-spell patterns
var nonspell_patterns: Array[String] = ["spread_5", "aimed_triple", "ring_12"]
var nonspell_duration: float = 20.0


func _init() -> void:
	_setup_stage_1_spells()


func _setup_stage_1_spells() -> void:
	# Stage 1 boss: 计算部部长 算盘
	spell_cards = [
		{"name": "算符「加减乘除」", "duration": 30.0, "pattern": "ring_12"},
		{"name": "珠算「九九归一」", "duration": 40.0, "pattern": "spread_5"},
		{"name": "终极「十进制崩溃」", "duration": 50.0, "pattern": "ring_12"},
	]


func start() -> void:
	phase = BossPhase.SPAWNING
	phase_timer = 0.0
	phase_index = 0
	_move_to_start_position()


func _move_to_start_position() -> void:
	# Boss moves to their starting Y position (handled by enemy_base path_type=STOP_AT_Y)
	pass


func update(delta: float, enemy: Node2D) -> String:
	"""Returns the pattern to fire this frame, or empty string"""
	phase_timer += delta

	match phase:
		BossPhase.SPAWNING:
			if phase_timer > 2.0:
				phase = BossPhase.NONSPELL
				phase_timer = 0.0
			return ""

		BossPhase.NONSPELL:
			return _update_nonspell(enemy)

		BossPhase.SPELL_CARD:
			return _update_spell_card(delta)

		BossPhase.DYING:
			return ""

	return ""


func _update_nonspell(enemy: Node2D) -> String:
	if phase_timer >= nonspell_duration:
		# Transition to spell card
		_start_spell_card()
		return ""

	# Alternate between different non-spell patterns
	var pattern_idx: int = int(phase_timer / 5.0) % nonspell_patterns.size()
	return nonspell_patterns[pattern_idx]


func _start_spell_card() -> void:
	phase = BossPhase.SPELL_CARD
	phase_timer = 0.0
	current_spell += 1

	if current_spell >= spell_cards.size():
		current_spell = spell_cards.size() - 1

	var card: Dictionary = spell_cards[current_spell]
	spell_timer = card["duration"]
	spell_card_started.emit(card["name"], spell_timer)


func _update_spell_card(delta: float) -> String:
	if current_spell < 0 or current_spell >= spell_cards.size():
		phase = BossPhase.NONSPELL
		phase_timer = 0.0
		spell_card_ended.emit(false)
		return ""

	var card: Dictionary = spell_cards[current_spell]
	spell_timer -= delta

	if spell_timer <= 0:
		# Time's up — spell card timeout
		spell_card_ended.emit(false)
		phase = BossPhase.NONSPELL
		phase_timer = 0.0
		return ""

	return card["pattern"]


func on_damaged(current_hp: float, max_hp: float) -> void:
	# Check spell card capture
	if phase == BossPhase.SPELL_CARD:
		if current_hp <= 0:
			spell_card_ended.emit(true)
			phase = BossPhase.NONSPELL
			phase_timer = 0.0


func get_display_name() -> String:
	return "计算部部长 算盘"


func get_current_spell_name() -> String:
	if current_spell >= 0 and current_spell < spell_cards.size():
		return spell_cards[current_spell]["name"]
	return ""
