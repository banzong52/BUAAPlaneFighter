# BossEnemy.gd — 海盗旗舰 Boss
extends "res://scripts/enemies/enemy_base.gd"

var phase: int = 1
var phase2_triggered: bool = false
var entering: bool = true
var boss_texture: String = ""
var pattern_timer: float = 0.0
var current_pattern: int = 0
var phase1_patterns: Array[String] = ["ring_12", "aimed_triple", "spread_5", "fan_aimed"]
var phase2_patterns: Array[String] = ["double_ring", "fan_aimed", "spiral_8", "ring_16", "spread_5"]

const SCREEN_TOP: float = 30.0
const SCREEN_BOTTOM: float = 280.0

func _ready() -> void:
	super._ready()
	if _sprite:
		var path: String = "res://assets/textures/enemies/" + boss_texture + ".png"
		if not boss_texture.is_empty() and FileAccess.file_exists(path):
			var img: Image = Image.load_from_file(ProjectSettings.globalize_path(path))
			if img:
				_sprite.texture = ImageTexture.create_from_image(img)
				_sprite.scale = Vector2(0.7, 0.7)
				_sprite.rotation_degrees = 180
		else:
			_sprite.texture = _make_boss_texture()
			_sprite.scale = Vector2(2.0, 2.0)

func _process(delta: float) -> void:
	if _damage_cd > 0:
		_damage_cd -= delta
	if not is_alive:
		return
	if _game == null or not _game.has_method("get_state"):
		return
	if _game.get_state() != 1:
		return
	enter_timer += delta
	clamp_boss_position()
	_update_boss_movement(delta)

	var hp_ratio: float = hp / max_hp
	if not phase2_triggered and hp_ratio <= 0.5:
		phase2_triggered = true
		phase = 2
		fire_interval = 0.4
		pattern_timer = 0.0
		current_pattern = 0
		_phase_transition_effect()

	if entering:
		pass
	elif phase == 2:
		_update_phase2_firing(delta)
	else:
		_update_firing(delta)

	if hit_flash_timer > 0:
		hit_flash_timer -= delta
		if hit_flash_timer <= 0 and _sprite:
			_sprite.modulate = Color.WHITE

func _update_boss_movement(delta: float) -> void:
	if entering:
		velocity.y = 40.0
		position += velocity * delta
		if global_position.y >= 100.0:
			entering = false
	else:
		velocity.x = sin(enter_timer * 0.7) * 90.0
		velocity.y = sin(enter_timer * 0.35) * 25.0
		position += velocity * delta
	clamp_boss_position()

func clamp_boss_position() -> void:
	global_position.x = clamp(global_position.x, 60.0, 420.0)
	global_position.y = clamp(global_position.y, SCREEN_TOP, SCREEN_BOTTOM)

func _update_firing(delta: float) -> void:
	pattern_timer += delta
	if pattern_timer >= 4.0:
		pattern_timer = 0.0
		current_pattern = (current_pattern + 1) % phase1_patterns.size()
		pattern_id = phase1_patterns[current_pattern]
	fire_timer -= delta
	if fire_timer <= 0:
		fire_timer = fire_interval
		_fire_pattern()

func _update_phase2_firing(delta: float) -> void:
	pattern_timer += delta
	if pattern_timer >= 2.5:
		pattern_timer = 0.0
		current_pattern = (current_pattern + 1) % phase2_patterns.size()
		pattern_id = phase2_patterns[current_pattern]
	fire_timer -= delta
	if fire_timer <= 0:
		fire_timer = fire_interval
		_fire_pattern()
		if randf() < 0.2:
			var st: float = TAU / 8.0
			for i in range(8):
				var d: Vector2 = Vector2.RIGHT.rotated(st * float(i) + enter_timer)
				_game.spawn_bullet(0, global_position, d, 90.0, {
					"bullet_color": Color.ORANGE, "is_player_bullet": false,
					"collision_radius": 5.0, "lifetime": 4.0})

func _phase_transition_effect() -> void:
	if _game and _game.has_method("spawn_bullet"):
		for ring in range(3):
			var spd: float = 50.0 + ring * 30.0
			var st: float = TAU / 20.0
			for i in range(20):
				var d: Vector2 = Vector2.RIGHT.rotated(st * float(i) + ring * 0.3)
				_game.spawn_bullet(1, global_position, d, spd, {
					"bullet_color": Color.RED, "is_player_bullet": false,
					"collision_radius": 8.0, "lifetime": 3.0})
	if _sprite:
		_sprite.modulate = Color(3.0, 1.0, 1.0, 1.0)
		hit_flash_timer = 0.6

func _fire_pattern() -> void:
	if not _game or not _game.has_method("get_player"):
		return
	var player: Node2D = _game.get_player()
	if player == null:
		return
	var pos: Vector2 = global_position
	var target: Vector2 = player.global_position
	var base_dir: Vector2 = (target - pos).normalized()
	match pattern_id:
		"ring_12":
			var step: float = TAU / 12.0
			for i in range(12):
				_game.spawn_bullet(1, pos, Vector2.RIGHT.rotated(step * float(i)), 100.0,
					{"bullet_color": Color.CYAN, "is_player_bullet": false, "collision_radius": 8.0})
		"aimed_triple":
			for off in [-0.12, 0.0, 0.12]:
				_game.spawn_bullet(1, pos, base_dir.rotated(off), 110.0,
					{"bullet_color": Color(0.9, 0.3, 0.3), "is_player_bullet": false, "collision_radius": 8.0})
		"spread_5":
			for i in range(5):
				var a: float = -0.25 + 0.125 * float(i)
				_game.spawn_bullet(1, pos, base_dir.rotated(a), 110.0,
					{"bullet_color": Color.ORANGE, "is_player_bullet": false, "collision_radius": 8.0})
		"fan_aimed":
			for i in range(11):
				var a: float = -0.5 + 0.1 * float(i)
				_game.spawn_bullet(1, pos, base_dir.rotated(a), 100.0,
					{"bullet_color": Color.PINK, "is_player_bullet": false, "collision_radius": 8.0})
		"double_ring":
			for i in range(20):
				var a: float = TAU * float(i) / 20.0
				_game.spawn_bullet(0, pos, Vector2.RIGHT.rotated(a), 80.0,
					{"bullet_color": Color.CYAN, "is_player_bullet": false, "collision_radius": 5.0})
				_game.spawn_bullet(1, pos, Vector2.RIGHT.rotated(a + 0.15), 120.0,
					{"bullet_color": Color.PINK, "is_player_bullet": false, "collision_radius": 8.0})
		"spiral_8":
			var t: float = enter_timer * 3.0
			for i in range(8):
				var a: float = TAU * float(i) / 8.0 + t
				_game.spawn_bullet(1, pos, Vector2.RIGHT.rotated(a), 110.0,
					{"bullet_color": Color.GREEN, "is_player_bullet": false, "collision_radius": 8.0, "angular_velocity": 0.8})
		"ring_16":
			var st: float = TAU / 16.0
			for i in range(16):
				_game.spawn_bullet(1, pos, Vector2.RIGHT.rotated(st * float(i)), 80.0,
					{"bullet_color": Color.PURPLE, "is_player_bullet": false, "collision_radius": 8.0})
		_:
			_game.spawn_bullet(1, pos, base_dir, 120.0,
				{"bullet_color": Color.RED, "is_player_bullet": false, "collision_radius": 8.0})

func _make_boss_texture() -> ImageTexture:
	var w: int = 96
	var h: int = 80
	var img: Image = Image.create(w, h, false, Image.FORMAT_RGBA8)
	var cx: float = w / 2.0
	for x in range(w):
		for y in range(h):
			var dx: float = abs(float(x) - cx)
			var ry: float = float(y) / float(h)
			var hull_w: float = 42.0 - ry * 18.0
			if dx < hull_w and y > 6:
				var shade: float = 0.15 + ry * 0.1
				img.set_pixel(x, y, Color(shade, shade * 0.7, shade * 0.5, 1.0))
			else:
				img.set_pixel(x, y, Color.TRANSPARENT)
	for x in range(35, 61):
		for y in range(8, 28):
			var dx2: float = abs(float(x) - 48.0)
			if dx2 < 11.0 - float(y - 8) * 0.25:
				var bone: float = 0.6 - float(y - 8) * 0.02
				img.set_pixel(x, y, Color(bone, bone * 0.85, bone * 0.7, 1.0))
	for x in range(39, 45):
		for y in range(12, 18):
			img.set_pixel(x, y, Color.RED)
	for x in range(51, 57):
		for y in range(12, 18):
			img.set_pixel(x, y, Color.RED)
	for x in range(25, 71):
		for y in range(65, 78):
			var dx3: float = abs(float(x) - 48.0)
			if dx3 < 18.0:
				var eg: float = 0.4 + (1.0 - dx3 / 18.0) * 0.6
				img.set_pixel(x, y, Color(1.0, 0.3, 0.1, eg * 0.7))
	for x in range(0, 96):
		for y in range(38, 50):
			var dx4: float = abs(float(x) - cx)
			if dx4 > 30.0 and dx4 < 46.0:
				img.set_pixel(x, y, Color(0.2, 0.12, 0.08, 1.0))
	for x in range(20, 76):
		for y in range(30, 36):
			if img.get_pixel(x, y).a > 0:
				img.set_pixel(x, y, Color(0.85, 0.1, 0.05, 1.0))
	return ImageTexture.create_from_image(img)
