# StageSelect.gd — 关卡选择
extends Control

var stages: Array[String] = [
	"Stage 1 - 小行星带",
	"Stage 2 - 星云边缘",
	"Stage 3 - 废弃空间站",
	"Stage 4 - 海盗前哨",
	"Stage 5 - 海盗要塞",
]
var selected_idx: int = 0
var labels: Array[Label] = []
var _confirm_ready: bool = false
var _x_down: bool = true
var _esc_down: bool = true


func _ready() -> void:
	var bg: ColorRect = ColorRect.new()
	bg.color = Color(0.03, 0.03, 0.1, 1)
	bg.size = Vector2(480, 720)
	add_child(bg)

	var title: Label = Label.new()
	title.text = "关卡选择"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.9, 0.85, 0.5))
	title.position = Vector2(140, 60)
	title.size = Vector2(200, 42)
	add_child(title)

	for i in stages.size():
		var label: Label = Label.new()
		label.text = stages[i]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 18)
		label.position = Vector2(100, 160 + i * 55)
		label.size = Vector2(280, 30)
		add_child(label)
		labels.append(label)

	var hint: Label = Label.new()
	hint.text = "↑↓ 选择  X 确定  ESC 返回"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	hint.position = Vector2(140, 600)
	hint.size = Vector2(200, 22)
	add_child(hint)

	_update_selection()
	await get_tree().create_timer(0.1).timeout
	_confirm_ready = true


func _process(_delta: float) -> void:
	if not _confirm_ready:
		return
	if Input.is_action_just_pressed("move_up"):
		selected_idx = wrapi(selected_idx - 1, 0, stages.size())
		_update_selection()
	if Input.is_action_just_pressed("move_down"):
		selected_idx = wrapi(selected_idx + 1, 0, stages.size())
		_update_selection()
	if Input.is_key_pressed(KEY_X) and not _x_down:
		_x_down = true
		_start_stage(selected_idx + 1)
	elif not Input.is_key_pressed(KEY_X):
		_x_down = false
	if Input.is_key_pressed(KEY_ESCAPE) and not _esc_down:
		_esc_down = true
		get_tree().change_scene_to_file("res://scenes/menus/title_screen.tscn")
	elif not Input.is_key_pressed(KEY_ESCAPE):
		_esc_down = false


func _update_selection() -> void:
	for i in labels.size():
		if i == selected_idx:
			labels[i].add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))
		else:
			labels[i].add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))


func _start_stage(stage: int) -> void:
	get_tree().root.set_meta("selected_stage", stage)
	get_tree().change_scene_to_file("res://scenes/game/game.tscn")
