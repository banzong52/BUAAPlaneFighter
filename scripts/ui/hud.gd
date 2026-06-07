# HUD.gd — 分数/火力/血量条
extends Control

var _game: Node = null
var _score_label: Label = null
var _power_label: Label = null
var _graze_label: Label = null
var _hp_bar_bg: ColorRect = null
var _hp_bar_fill: ColorRect = null
var _shield_label: Label = null
var _drone_label: Label = null


func _ready() -> void:
	_game = get_node_or_null("/root/Game")
	_create_ui()


func _create_ui() -> void:
	_score_label = _make_label("Score", Vector2(12, 8), 14, Color.WHITE)
	_graze_label = _make_label("Graze", Vector2(12, 28), 14, Color.WHITE)
	_power_label = _make_label("Power", Vector2(12, 48), 14, Color.WHITE)

	# HP bar at bottom-left (no text label)
	_hp_bar_bg = ColorRect.new()
	_hp_bar_bg.color = Color(0.15, 0.15, 0.15, 0.8)
	_hp_bar_bg.position = Vector2(12, 698)
	_hp_bar_bg.size = Vector2(160, 14)
	add_child(_hp_bar_bg)

	_hp_bar_fill = ColorRect.new()
	_hp_bar_fill.color = Color(0.0, 0.8, 0.2)
	_hp_bar_fill.position = Vector2(12, 698)
	_hp_bar_fill.size = Vector2(160, 14)
	add_child(_hp_bar_fill)


func _make_label(text: String, pos: Vector2, sz: int, color: Color) -> Label:
	var l: Label = Label.new()
	l.position = pos
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	l.add_theme_constant_override("outline_size", 1)
	add_child(l)
	return l


func _process(_delta: float) -> void:
	if _game == null:
		_game = get_node_or_null("/root/Game")
		return
	_score_label.text = "SCORE: %010d" % _game.get("score")
	_graze_label.text = "GRAZE: %d" % _game.get("graze_count")

	var pwr: float = _game.get("power")
	var level: int = int(pwr * 2.0)
	var seg: String = ""
	for i in range(8):
		seg += "■ " if i < level else "□ "
	_power_label.text = "POWER: " + seg

	# HP bar (no text)
	var hp: float = _game.get("player_hp")
	var max_hp: float = _game.get("player_max_hp")
	var ratio: float = clamp(hp / max_hp, 0.0, 1.0)
	_hp_bar_fill.size.x = 160.0 * ratio
	if ratio > 0.5:
		_hp_bar_fill.color = Color(0.0, 0.8, 0.2)
	elif ratio > 0.25:
		_hp_bar_fill.color = Color(0.9, 0.8, 0.1)
	else:
		_hp_bar_fill.color = Color(0.9, 0.1, 0.1)

	# Shield indicator
	var sl: int = _game.get("shield_layers")
	if sl > 0:
		if _shield_label == null:
			_shield_label = _make_label("", Vector2(12, 676), 12, Color(0.3, 0.6, 1.0))
		_shield_label.text = "SHIELD: " + ("O" if sl == 1 else ("OO" if sl == 2 else "OOO"))
	elif _shield_label:
		_shield_label.text = ""

	# Drone indicator
	if _game.get("drone_active"):
		if _drone_label == null:
			_drone_label = _make_label("", Vector2(120, 676), 12, Color(0.0, 0.9, 0.9))
		_drone_label.text = "DRONE: ON"
	elif _drone_label:
		_drone_label.text = ""
