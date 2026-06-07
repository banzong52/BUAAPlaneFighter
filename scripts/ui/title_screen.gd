# TitleScreen.gd — 主菜单
extends Control

var menu_items: Array[String] = ["关卡选择", "退出"]
var selected_idx: int = 0
var labels: Array[Label] = []
var _confirm_ready: bool = false
var _x_down: bool = true


func _ready() -> void:
	_create_title()
	_start_title_bgm()
	await get_tree().create_timer(0.1).timeout
	_confirm_ready = true


func _start_title_bgm() -> void:
	var bgm: Node = load("res://scripts/systems/bgm_player.gd").new()
	bgm.name = "BGM"
	add_child(bgm)
	if bgm.has_method("play_title"):
		bgm.play_title()


func _create_title() -> void:
	var bg: ColorRect = ColorRect.new()
	bg.color = Color(0.02, 0.02, 0.08, 1)
	bg.size = Vector2(480, 720)
	add_child(bg)
	for i in range(60):
		var star: ColorRect = ColorRect.new()
		star.color = Color.WHITE
		star.size = Vector2(2, 2)
		star.position = Vector2(randf_range(0, 480), randf_range(0, 720))
		add_child(star)

	var title: Label = Label.new()
	title.text = "北航一百号"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color(0.9, 0.85, 0.5))
	title.position = Vector2(140, 120)
	title.size = Vector2(200, 56)
	add_child(title)

	var sub: Label = Label.new()
	sub.text = "BUAA-100 Space Fighter"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 16)
	sub.add_theme_color_override("font_color", Color(0.5, 0.6, 0.8))
	sub.position = Vector2(140, 178)
	sub.size = Vector2(200, 24)
	add_child(sub)

	var hint: Label = Label.new()
	hint.text = "北航一百号 - 宇宙战机"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.6, 0.65, 0.75))
	hint.position = Vector2(140, 540)
	hint.size = Vector2(200, 20)
	add_child(hint)

	# Control guide
	var guide: Label = Label.new()
	guide.text = "鼠标 - 移动    X - 确定    ESC - 退出"
	guide.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	guide.add_theme_font_size_override("font_size", 12)
	guide.add_theme_color_override("font_color", Color(0.45, 0.5, 0.6))
	guide.position = Vector2(140, 620)
	guide.size = Vector2(200, 20)
	add_child(guide)

	for i in menu_items.size():
		var label: Label = Label.new()
		label.text = menu_items[i]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 22)
		label.position = Vector2(140, 320 + i * 50)
		label.size = Vector2(200, 34)
		add_child(label)
		labels.append(label)
	_update_selection()


func _process(_delta: float) -> void:
	if not _confirm_ready:
		return
	if Input.is_action_just_pressed("move_up"):
		selected_idx = wrapi(selected_idx - 1, 0, menu_items.size())
		_update_selection()
	if Input.is_action_just_pressed("move_down"):
		selected_idx = wrapi(selected_idx + 1, 0, menu_items.size())
		_update_selection()
	if Input.is_key_pressed(KEY_X) and not _x_down:
		_x_down = true
		_on_select()
	elif not Input.is_key_pressed(KEY_X):
		_x_down = false


func _update_selection() -> void:
	for i in labels.size():
		if i == selected_idx:
			labels[i].add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))
			labels[i].text = "▶ " + menu_items[i] + " ◀"
		else:
			labels[i].add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
			labels[i].text = "   " + menu_items[i] + "   "


func _on_select() -> void:
	match selected_idx:
		0:
			get_tree().change_scene_to_file("res://scenes/menus/stage_select.tscn")
		1:
			get_tree().quit()
