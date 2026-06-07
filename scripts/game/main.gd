# Main.gd — 雷霆战机 游戏主控
extends Node

enum State { TITLE, PLAYING, PAUSED, STAGE_CLEAR, GAME_OVER }

@onready var world: Node2D = $World
@onready var player_layer: Node2D = $World/PlayerLayer
@onready var bullet_layer: Node2D = $World/BulletLayer
@onready var enemy_layer: Node2D = $World/EnemyLayer
@onready var item_layer: Node2D = $World/ItemLayer
@onready var hud_ctrl: Control = $UI/HUD
@onready var boss_hud_ctrl: Control = $UI/BossHUD

var current_state: int = State.PLAYING
var player_node: Node2D = null
var current_stage: int = 1

var score: int = 0
var graze_count: int = 0
var power: float = 1.00
var player_hp: float = 100.0
var player_max_hp: float = 100.0
var shield_layers: int = 0
var drone_active: bool = false
var drone_timer: float = 0.0
const DRONE_INTERVAL: float = 1.5

const POOL_SIZE: int = 500
var _bullet_scene: PackedScene = null
var _active_bullets: Array[Node2D] = []
var _bullet_pools: Dictionary = {}

var active_enemies: Array[Node2D] = []

const PLAYER_SPEED: float = 12.0
const SHOT_INTERVAL: float = 0.15

var shot_timer: float = 0.0
var invincible: bool = false
var invincible_timer: float = 0.0
var boss_spawned: bool = false
var _boss_killed: bool = false
var stage_time: float = 0.0
var _cleanup_timer: float = 0.0
var paused: bool = false
var resume_countdown: float = 0.0
var _x_was_down: bool = true
var _bgm_node: Node = null
var elite_count: int = 0
var boss_entering: bool = false
var warning_timer: float = 0.0
var current_wave: int = 0
var _wave_clear_timer: float = 0.0

# Stage config: {stage_num: {waves: [...], boss_hp: ..., boss_name: ..., boss_fire: ...}}
var _stage_data: Dictionary = {
	1: {
			"waves": [
			["grunt", "grunt"],
			["grunt", "grunt", "fairy"],
			["grunt", "fairy", "fairy"],
			["fairy", "fairy", "fairy"],
			["fairy", "fairy", "medium"],
			["medium", "medium", "fairy"],
		],
			"boss_hp": 200.0,
			"boss_name": "巡逻舰",
			"boss_fire": 1.0,
	},
	2: {
			"waves": [
			["grunt", "fairy", "fairy"],
			["fairy", "fairy", "fairy"],
			["fairy", "medium", "fairy"],
			["medium", "medium", "fairy"],
			["medium", "medium", "medium"],
			["medium", "elite", "fairy"],
		],
			"boss_hp": 250.0,
			"boss_name": "突击舰",
			"boss_fire": 0.85,
	},
	3: {
			"waves": [
			["fairy", "fairy", "fairy", "grunt"],
			["fairy", "medium", "fairy", "fairy"],
			["medium", "medium", "fairy", "grunt"],
			["medium", "medium", "elite", "fairy"],
			["medium", "elite", "fairy", "medium"],
			["elite", "medium", "medium", "elite"],
		],
			"boss_hp": 300.0,
			"boss_name": "驱逐舰",
			"boss_fire": 0.75,
	},
	4: {
			"waves": [
			["fairy", "medium", "fairy", "grunt"],
			["medium", "fairy", "medium", "medium"],
			["medium", "elite", "fairy", "medium"],
			["elite", "medium", "elite", "fairy"],
			["elite", "elite", "medium", "medium"],
			["elite", "elite", "elite", "fairy"],
		],
			"boss_hp": 350.0,
			"boss_name": "巡空舰",
			"boss_fire": 0.65,
	},
	5: {
			"waves": [
			["medium", "fairy", "medium", "grunt"],
			["medium", "medium", "elite", "fairy"],
			["elite", "medium", "elite", "medium"],
			["elite", "elite", "medium", "medium"],
			["elite", "elite", "elite", "fairy"],
			["elite", "elite", "elite", "elite"],
		],
			"boss_hp": 400.0,
			"boss_name": "海盗旗舰",
			"boss_fire": 0.55,
	},
}


func _ready() -> void:
	current_stage = get_tree().root.get_meta("selected_stage", 1)
	preload_resources()
	spawn_player()
	current_wave = 0
	_spawn_wave(current_wave)
	_start_bgm()


func _start_bgm() -> void:
	_bgm_node = load("res://scripts/systems/bgm_player.gd").new()
	_bgm_node.name = "BGM"
	add_child(_bgm_node)
	if _bgm_node.has_method("play_game"):
		_bgm_node.play_game()


func _process(delta: float) -> void:
	if current_state == State.GAME_OVER:
		if Input.is_action_just_pressed("bomb"):
			get_tree().change_scene_to_file("res://scenes/menus/title_screen.tscn")
		return
	if current_state == State.STAGE_CLEAR:
		if Input.is_action_just_pressed("bomb"):
			get_tree().change_scene_to_file("res://scenes/menus/title_screen.tscn")
		return
	_check_pause()
	if paused:
		if Input.is_key_pressed(KEY_X) and not _x_was_down:
			_x_was_down = true
			get_tree().change_scene_to_file("res://scenes/menus/title_screen.tscn")
			return
		elif not Input.is_key_pressed(KEY_X):
			_x_was_down = false
		return
	if resume_countdown > 0.0:
		resume_countdown -= delta
		var cd_label: Label = $PauseOverlay.get_node_or_null("CountdownLabel") as Label
		if cd_label:
			cd_label.text = str(int(ceil(resume_countdown)))
		if resume_countdown <= 0.0:
			resume_countdown = 0.0
			current_state = State.PLAYING
			$PauseOverlay.visible = false
		return
	if current_state != State.PLAYING:
		return
	stage_time += delta
	# Wave progression
	if not boss_spawned and not boss_entering and active_enemies.size() == 0:
		_wave_clear_timer += delta
		if _wave_clear_timer > 1.0:
			_wave_clear_timer = 0.0
			current_wave += 1
			_spawn_wave(current_wave)
	else:
		_wave_clear_timer = 0.0
	# Boss entrance
	if boss_entering and not boss_spawned:
		warning_timer += delta
		if warning_timer > 2.0:
			boss_entering = false
			spawn_boss()
	if is_instance_valid(player_node):
		_update_player_movement(delta)
		_update_player_shooting(delta)
		_update_player_state_timers(delta)
	_update_all_bullets(delta)
	_check_collisions()
	if drone_active:
		_update_drone(delta)


func preload_resources() -> void:
	_bullet_scene = load("res://scenes/bullets/bullet_base.tscn")
	for type_idx in range(10):
		var pool: Array[Node2D] = []
		for i in range(POOL_SIZE):
			if _bullet_scene:
				var bullet: Node2D = _bullet_scene.instantiate()
				bullet.visible = false
				bullet.process_mode = Node.PROCESS_MODE_DISABLED
				pool.append(bullet)
		_bullet_pools[type_idx] = pool


func spawn_player() -> void:
	var ps: PackedScene = load("res://scenes/player/player.tscn")
	if ps == null:
		return
	player_node = ps.instantiate()
	player_node.name = "Player"
	player_node.global_position = Vector2(240, 600)
	player_layer.add_child(player_node)


func _spawn_wave(wave_idx: int) -> void:
	if wave_idx >= _stage_data[current_stage]["waves"].size():
		_show_warning_danger()
		boss_entering = true
		warning_timer = 0.0
		return
	var enemies: Array = _stage_data[current_stage]["waves"][wave_idx]
	for i in enemies.size():
		var type: String = enemies[i]
		var path: String = "res://scenes/enemies/" + type + ".tscn"
		var sc: PackedScene = load(path)
		if sc == null:
			continue
		var e: Node2D = sc.instantiate()
		e.global_position = Vector2(randf_range(60, 420), -40 - i * 40)
		enemy_layer.add_child(e)
		active_enemies.append(e)
		if e.has_signal("destroyed"):
			e.destroyed.connect(_on_enemy_destroyed)


func _show_warning_danger() -> void:
	var go: CanvasLayer = $GameOverOverlay
	go.visible = true
	for c in go.get_children():
		c.queue_free()
	var bg: ColorRect = ColorRect.new()
	bg.color = Color(1.0, 0.0, 0.0, 0.3)
	bg.size = Vector2(480, 720)
	go.add_child(bg)
	var l1: Label = Label.new()
	l1.text = "WARNING"
	l1.add_theme_font_size_override("font_size", 44)
	l1.add_theme_color_override("font_color", Color.RED)
	l1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l1.position = Vector2(140, 280)
	l1.size = Vector2(200, 50)
	go.add_child(l1)
	var l2: Label = Label.new()
	l2.text = "DANGER"
	l2.add_theme_font_size_override("font_size", 36)
	l2.add_theme_color_override("font_color", Color(1.0, 0.7, 0.0))
	l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l2.position = Vector2(140, 340)
	l2.size = Vector2(200, 50)
	go.add_child(l2)
	get_tree().create_timer(1.5).timeout.connect(func(): go.visible = false)


func spawn_boss() -> void:
	boss_spawned = true
	if _bgm_node and _bgm_node.has_method("play_boss"):
		_bgm_node.play_boss()
	var bs: PackedScene = load("res://scenes/enemies/boss.tscn")
	if bs == null:
		return
	var boss: Node2D = bs.instantiate()
	boss.set("fire_interval", _stage_data[current_stage]["boss_fire"])
	boss.set("max_hp", _stage_data[current_stage]["boss_hp"])
	var tex_map: Dictionary = {1:"patrol", 2:"assault", 3:"destroyer", 4:"battlecruiser", 5:"flag"}
	boss.set("boss_texture", tex_map.get(current_stage, "flag"))
	boss.global_position = Vector2(240, -80)
	enemy_layer.add_child(boss)
	active_enemies.append(boss)
	if boss.has_signal("destroyed"):
		boss.destroyed.connect(_on_enemy_destroyed)
	if boss_hud_ctrl and boss_hud_ctrl.has_method("show_boss"):
		boss_hud_ctrl.show_boss(_stage_data[current_stage]["boss_name"], _stage_data[current_stage]["boss_hp"])


func _update_player_movement(delta: float) -> void:
	var mp: Vector2 = get_viewport().get_mouse_position()
	var vp: Vector2 = get_viewport().get_visible_rect().size
	var target: Vector2 = mp.clamp(Vector2(24, 24), Vector2(vp.x - 24, vp.y - 24))
	player_node.position = player_node.position.lerp(target, PLAYER_SPEED * delta)


func _update_player_shooting(delta: float) -> void:
	shot_timer -= delta
	if shot_timer > 0:
		return
	shot_timer = SHOT_INTERVAL
	_fire_player_bullets()


func _fire_player_bullets() -> void:
	var pl: int = int(power * 2.0)
	var count: int = 1 + min(int(float(pl) / 2.0), 3)
	var spread: float = 6.0 + pl * 1.5
	var base_angle: float = -90.0
	var total_spread: float = spread * float(count - 1)
	var start_angle: float = base_angle - total_spread / 2.0
	for i in range(count):
		var ad: float = start_angle + spread * float(i)
		var dir: Vector2 = Vector2.RIGHT.rotated(deg_to_rad(ad))
		var off: Vector2 = Vector2(randf_range(-3, 3), -16)
		spawn_bullet(8, player_node.global_position + off, dir, 500.0, {
			"bullet_color": Color.YELLOW, "is_player_bullet": true, "damage": 1.0, "lifetime": 1.5})
	if pl >= 6:
		spawn_bullet(9, player_node.global_position + Vector2(-12, -16), Vector2.UP, 500.0, {
			"bullet_color": Color.ORANGE_RED, "is_player_bullet": true, "damage": 3.0, "lifetime": 1.5})
		spawn_bullet(9, player_node.global_position + Vector2(12, -16), Vector2.UP, 500.0, {
			"bullet_color": Color.ORANGE_RED, "is_player_bullet": true, "damage": 3.0, "lifetime": 1.5})


func _check_pause() -> void:
	if resume_countdown > 0.0:
		return
	var esc_pressed: bool = Input.is_action_just_pressed("pause")
	var mouse_in: bool = get_viewport().get_visible_rect().has_point(get_viewport().get_mouse_position())

	# Unpause first (ESC while paused → start countdown)
	if paused and esc_pressed:
		paused = false
		resume_countdown = 3.0
		for c in $PauseOverlay.get_children():
			c.queue_free()
		var bg2: ColorRect = ColorRect.new()
		bg2.color = Color(0, 0, 0, 0.6)
		bg2.size = get_viewport().get_visible_rect().size
		$PauseOverlay.add_child(bg2)
		var cd_label: Label = Label.new()
		cd_label.name = "CountdownLabel"
		cd_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cd_label.add_theme_font_size_override("font_size", 60)
		cd_label.add_theme_color_override("font_color", Color.WHITE)
		cd_label.position = Vector2(140, 300)
		cd_label.size = Vector2(200, 80)
		cd_label.text = "3"
		$PauseOverlay.add_child(cd_label)
		return

	# Pause (ESC or mouse out while playing)
	if esc_pressed or (not mouse_in and current_state == State.PLAYING):
		paused = true
		current_state = State.PAUSED
		$PauseOverlay.visible = true
		for c in $PauseOverlay.get_children():
			c.queue_free()
		var bg: ColorRect = ColorRect.new()
		bg.color = Color(0, 0, 0, 0.6)
		bg.size = get_viewport().get_visible_rect().size
		$PauseOverlay.add_child(bg)
		var label: Label = Label.new()
		label.text = "PAUSED\nESC - 继续\nX - 返回菜单"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 22)
		label.add_theme_color_override("font_color", Color.WHITE)
		label.position = Vector2(140, 270)
		label.size = Vector2(200, 120)
		$PauseOverlay.add_child(label)
		return



func _update_player_state_timers(delta: float) -> void:
	if invincible:
		invincible_timer -= delta
		# Blink effect
		if is_instance_valid(player_node):
			var s: Sprite2D = player_node.get_node_or_null("Sprite") as Sprite2D
			if s:
				s.visible = int(invincible_timer * 20.0) % 2 == 0
		if invincible_timer <= 0.0:
			invincible = false
			if is_instance_valid(player_node):
				var s: Sprite2D = player_node.get_node_or_null("Sprite") as Sprite2D
				if s:
					s.visible = true


func spawn_bullet(bt: int, pos: Vector2, dir: Vector2, spd: float, config: Dictionary = {}) -> Node2D:
	var pool: Array = _bullet_pools.get(bt, [])
	var bullet: Node2D = null
	if pool.size() > 0:
		bullet = pool.pop_back()
	elif _bullet_scene:
		bullet = _bullet_scene.instantiate()
	if bullet == null:
		return null
	bullet.global_position = pos
	bullet.set("bullet_type", bt)
	bullet.set("direction", dir)
	bullet.set("speed", spd)
	bullet.set("age", 0.0)
	bullet.set("grazed", false)
	bullet.set("collision_radius", 6.0)
	bullet.visible = true
	bullet.process_mode = Node.PROCESS_MODE_INHERIT
	for key in config:
		bullet.set(key, config[key])
	bullet_layer.add_child(bullet)
	_active_bullets.append(bullet)
	return bullet


func despawn_bullet(bullet: Node2D) -> void:
	if not is_instance_valid(bullet):
		return
	_active_bullets.erase(bullet)
	var bt = bullet.get("bullet_type")
	var pool: Array = _bullet_pools.get(bt, [])
	bullet.visible = false
	bullet.process_mode = Node.PROCESS_MODE_DISABLED
	if bullet.has_method("reset_state"):
		bullet.reset_state()
	bullet.get_parent().remove_child(bullet)
	pool.append(bullet)


func despawn_all_enemy_bullets() -> void:
	var td: Array[Node2D] = []
	for b in _active_bullets:
		if is_instance_valid(b) and not b.get("is_player_bullet"):
			td.append(b)
	for b in td:
		despawn_bullet(b)


func _update_all_bullets(delta: float) -> void:
	for b in _active_bullets:
		if not is_instance_valid(b) or not b.visible:
			continue
		if b.has_method("update_bullet"):
			b.update_bullet(delta)
	_cleanup_timer += delta
	if _cleanup_timer > 2.0:
		_cleanup_timer = 0.0
		var i: int = _active_bullets.size() - 1
		while i >= 0:
			if not is_instance_valid(_active_bullets[i]) or not _active_bullets[i].visible:
				_active_bullets.remove_at(i)
			i -= 1


func _check_collisions() -> void:
	if not is_instance_valid(player_node) or invincible:
		return
	var hp: Vector2 = player_node.global_position
	var hr: float = 3.0
	var gr: float = 50.0
	# Enemy bullets vs player
	for b in _active_bullets:
		if not is_instance_valid(b) or not b.visible:
			continue
		if b.get("is_player_bullet"):
			continue
		var br: float = b.get("collision_radius")
		if hp.distance_to(b.global_position) < (hr + br):
			_hit_player(b)
			return
		if not b.grazed and hp.distance_to(b.global_position) < (gr + br):
			b.grazed = true
			graze_count += 1
			add_score(500)
	# Player bullets vs enemies + contact damage + boss HP update
	for enemy: Node2D in active_enemies:
		if not is_instance_valid(enemy) or not enemy.is_alive:
			continue
		var er: float = enemy.get("collision_radius")
		var ep: Vector2 = enemy.global_position
		# Grunt contact damage
		var cd: float = enemy.get("contact_damage")
		if cd > 0.0 and ep.distance_to(hp) < (er + hr):
			_hit_player(null)
			if enemy.has_method("destroy"):
				enemy.destroy()
			continue
		# Bullet hits
		for b in _active_bullets:
			if not is_instance_valid(b) or not b.visible:
				continue
			if not b.get("is_player_bullet"):
				continue
			if ep.distance_to(b.global_position) < (er + b.get("collision_radius")):
				if enemy.has_method("take_damage"):
					enemy.take_damage(b.get("damage"))
				despawn_bullet(b)
				# Update boss HP bar
				if enemy.get("is_boss") and boss_hud_ctrl and boss_hud_ctrl.has_method("update_hp"):
					boss_hud_ctrl.update_hp(enemy.get("hp"))
				break
	# Check boss death
	if boss_spawned:
		var boss_alive: bool = false
		for enemy: Node2D in active_enemies:
			if enemy.get("is_boss") and enemy.is_alive:
				boss_alive = true
				break
		if not boss_alive and not _boss_killed:
			_boss_killed = true
			_stage_clear()


func _hit_player(bullet: Node2D = null) -> void:
	if bullet:
		despawn_bullet(bullet)
	if invincible:
		return
	# Shield absorbs hit first
	if shield_layers > 0:
		shield_layers -= 1
		invincible = true
		invincible_timer = 0.5
		return
	var dmg: float = 10.0 if bullet else 20.0
	player_hp -= dmg
	invincible = true
	invincible_timer = 1.0
	if player_hp <= 0:
		player_hp = 0
		current_state = State.GAME_OVER
		_show_game_over()
		return
	if is_instance_valid(player_node):
		var s: Sprite2D = player_node.get_node_or_null("Sprite") as Sprite2D
		if s:
			s.modulate = Color.RED
			var tw: Tween = create_tween()
			tw.tween_property(s, "modulate", Color.WHITE, 0.3)


func _show_game_over() -> void:
	var go: CanvasLayer = $GameOverOverlay
	go.visible = true
	for c in go.get_children():
		c.queue_free()
	var bg: ColorRect = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.7)
	bg.size = get_viewport().get_visible_rect().size
	go.add_child(bg)
	var label: Label = Label.new()
	label.text = "GAME OVER"
	label.add_theme_font_size_override("font_size", 40)
	label.add_theme_color_override("font_color", Color.RED)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(140, 250)
	label.size = Vector2(200, 60)
	go.add_child(label)
	var sub: Label = Label.new()
	sub.text = "Score: %d\nPress X to return to menu" % score
	sub.add_theme_font_size_override("font_size", 18)
	sub.add_theme_color_override("font_color", Color.WHITE)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.position = Vector2(140, 340)
	sub.size = Vector2(200, 60)
	go.add_child(sub)


func _stage_clear() -> void:
	current_state = State.STAGE_CLEAR
	if boss_hud_ctrl and boss_hud_ctrl.has_method("hide_boss"):
		boss_hud_ctrl.hide_boss()
	var go: CanvasLayer = $GameOverOverlay
	go.visible = true
	for c in go.get_children():
		c.queue_free()
	var bg: ColorRect = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.6)
	bg.size = get_viewport().get_visible_rect().size
	go.add_child(bg)
	var label: Label = Label.new()
	label.text = "STAGE CLEAR!"
	label.add_theme_font_size_override("font_size", 36)
	label.add_theme_color_override("font_color", Color.GOLD)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(140, 260)
	label.size = Vector2(200, 60)
	go.add_child(label)
	var sub: Label = Label.new()
	sub.text = "Score: %d\nPress X to return to menu" % score
	sub.add_theme_font_size_override("font_size", 18)
	sub.add_theme_color_override("font_color", Color.WHITE)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.position = Vector2(140, 340)
	sub.size = Vector2(200, 60)
	go.add_child(sub)


func _restart_game() -> void:
	$GameOverOverlay.visible = false
	player_hp = player_max_hp
	shield_layers = 0
	drone_active = false
	power = 1.0
	score = 0
	graze_count = 0
	invincible = false
	boss_spawned = false
	_boss_killed = false
	elite_count = 0
	warning_timer = 0.0
	boss_entering = false
	current_wave = 0
	stage_time = 0.0
	if boss_hud_ctrl and boss_hud_ctrl.has_method("hide_boss"):
		boss_hud_ctrl.hide_boss()
	despawn_all_enemy_bullets()
	for e in active_enemies:
		if is_instance_valid(e) and e.has_method("destroy"):
			e.destroy()
	active_enemies.clear()
	_spawn_wave(0)
	current_state = State.PLAYING


func _on_enemy_destroyed(enemy: Node) -> void:
	if enemy.get("enemy_id") == "elite":
		elite_count = max(0, elite_count - 1)
	active_enemies.erase(enemy)


func add_score(amount: int) -> void:
	score += amount


func add_power(amount: float) -> void:
	power = clamp(power + amount, 0.0, 4.0)


func get_player() -> Node2D:
	return player_node if is_instance_valid(player_node) else null


func get_state() -> int:
	return current_state


func get_bullet_layer() -> Node2D:
	return bullet_layer


func get_enemy_layer() -> Node2D:
	return enemy_layer


func _update_drone(delta: float) -> void:
	# Draw drone as small orbiting sprite
	if not is_instance_valid(player_node):
		return
	drone_timer -= delta
	if drone_timer <= 0:
		drone_timer = DRONE_INTERVAL
		# Find nearest alive enemy
		var nearest: Node2D = null
		var nearest_dist: float = 9999.0
		var pp: Vector2 = player_node.global_position
		for enemy: Node2D in active_enemies:
			if not is_instance_valid(enemy) or not enemy.is_alive:
				continue
			var d: float = pp.distance_to(enemy.global_position)
			if d < nearest_dist:
				nearest_dist = d
				nearest = enemy
			if nearest:
				var dir: Vector2 = (nearest.global_position - pp).normalized()
				for j in range(3):
					var laser_off: Vector2 = Vector2(randf_range(-6, 6), randf_range(-6, 6))
					spawn_bullet(9, pp + dir * 20.0 + laser_off, dir, 800.0, {
						"bullet_color": Color.CYAN, "is_player_bullet": true, "damage": 3.0,
						"collision_radius": 6.0, "lifetime": 0.8})


func get_item_layer() -> Node2D:
	return item_layer
