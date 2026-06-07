# BossHUD.gd — Boss health bar and spell card timer
extends Control

var boss_name_label: Label = null
var spell_name_label: Label = null
var hp_bar_bg: ColorRect = null
var hp_bar_fill: ColorRect = null
var timer_label: Label = null
var boss_max_hp: float = 1.0
var boss_current_hp: float = 1.0
var spell_timer: float = 0.0
var is_visible_flag: bool = false


func _ready() -> void:
	_create_ui()
	visible = false


func _create_ui() -> void:
	boss_name_label = Label.new()
	boss_name_label.position = Vector2(180, 8)
	boss_name_label.add_theme_font_size_override("font_size", 16)
	boss_name_label.add_theme_color_override("font_color", Color.WHITE)
	add_child(boss_name_label)

	spell_name_label = Label.new()
	spell_name_label.position = Vector2(180, 28)
	spell_name_label.add_theme_font_size_override("font_size", 14)
	spell_name_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.4))
	add_child(spell_name_label)

	hp_bar_bg = ColorRect.new()
	hp_bar_bg.position = Vector2(90, 50)
	hp_bar_bg.size = Vector2(300, 12)
	hp_bar_bg.color = Color(0.2, 0.2, 0.2, 0.8)
	add_child(hp_bar_bg)

	hp_bar_fill = ColorRect.new()
	hp_bar_fill.position = Vector2(90, 50)
	hp_bar_fill.size = Vector2(300, 12)
	hp_bar_fill.color = Color(0.9, 0.2, 0.2)
	add_child(hp_bar_fill)

	timer_label = Label.new()
	timer_label.position = Vector2(400, 28)
	timer_label.add_theme_font_size_override("font_size", 16)
	timer_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	add_child(timer_label)


func _process(delta: float) -> void:
	if not is_visible_flag:
		return
	var ratio: float = boss_current_hp / boss_max_hp
	var target_width: float = 300.0 * ratio
	hp_bar_fill.size.x = lerp(hp_bar_fill.size.x, target_width, 10.0 * delta)
	if spell_timer > 0:
		spell_timer -= delta
		var mins: int = int(spell_timer / 60.0)
		var secs: int = int(spell_timer) % 60
		timer_label.text = "%02d:%02d" % [mins, secs]
		if spell_timer <= 0:
			spell_timer = 0.0
			timer_label.text = "00:00"


func show_boss(boss_name: String, max_hp_val: float) -> void:
	boss_name_label.text = boss_name
	boss_max_hp = max_hp_val
	boss_current_hp = max_hp_val
	is_visible_flag = true
	visible = true


func hide_boss() -> void:
	is_visible_flag = false
	visible = false


func update_hp(current_hp: float) -> void:
	boss_current_hp = current_hp


func show_spell_card(spell_name: String, duration: float) -> void:
	spell_name_label.text = spell_name
	spell_timer = duration
	spell_name_label.visible = true
	timer_label.visible = true


func hide_spell_card() -> void:
	spell_name_label.visible = false
	timer_label.visible = false
	spell_timer = 0.0
