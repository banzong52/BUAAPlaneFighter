# EnemyBase.gd — 多层级敌人基类
extends CharacterBody2D

signal destroyed(enemy: Node)
signal damaged(amount: float, current_hp: float)

@export var enemy_id: String = "grunt"
@export var max_hp: float = 5.0
@export var defense: float = 0.0
@export var score_value: int = 100
@export var power_drop: float = 0.05
@export var point_item_drops: int = 1
@export var move_speed: float = 150.0
@export var collision_radius: float = 16.0
@export var is_boss: bool = false
@export var can_shoot: bool = true
@export var pattern_id: String = "aimed_single"
@export var fire_interval: float = 1.5
@export var contact_damage: float = 0.0
@export var hover_at_y: float = -1.0
@export var color_tint: Color = Color.RED
@export var drop_chance: float = 1.0
@export var damage_cooldown: float = 0.12

var hp: float = 5.0
var is_alive: bool = true
var fire_timer: float = 0.0
var enter_timer: float = 0.0
var hit_flash_timer: float = 0.0
var _damage_cd: float = 0.0

var _game: Node = null
var _sprite: Sprite2D = null


func _ready() -> void:
	hp = max_hp
	fire_timer = randf_range(0.0, fire_interval)
	_game = get_node_or_null("/root/Game")
	_sprite = Sprite2D.new()
	_sprite.name = "Sprite"
	_sprite.centered = true
	add_child(_sprite)
	_sprite.texture = _make_placeholder()
	if hover_at_y < 0:
		hover_at_y = randf_range(120.0, 350.0)


func _process(delta: float) -> void:
	if not is_alive:
		return
	if _game == null or not _game.has_method("get_state"):
		return
	if _game.get_state() != 1:
		return
	enter_timer += delta
	_update_movement(delta)
	if can_shoot:
		_update_firing(delta)
	if _damage_cd > 0:
		_damage_cd -= delta
	if hit_flash_timer > 0:
		hit_flash_timer -= delta
		if hit_flash_timer <= 0 and _sprite:
			_sprite.modulate = Color.WHITE


func _update_movement(_delta: float) -> void:
	if hover_at_y <= 0:
		# Grunt: fly straight down, no hovering
		velocity = Vector2(0, move_speed)
	else:
		# Hover type: descend to hover_at_y, then drift
		if global_position.y < hover_at_y:
			velocity = Vector2(0, move_speed)
		else:
			velocity = Vector2(sin(enter_timer * 1.5) * 40.0, 0)
	move_and_slide()
	if global_position.y > get_viewport().get_visible_rect().size.y + 100:
		destroy()


func _update_firing(delta: float) -> void:
	fire_timer -= delta
	if fire_timer <= 0:
		fire_timer = fire_interval
		_fire_pattern()


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
		"aimed_single":
			_game.spawn_bullet(1, pos, base_dir, 130.0, {"bullet_color": Color.RED, "is_player_bullet": false, "collision_radius": 8.0})
		"aimed_double":
			for off in [-0.1, 0.1]:
				_game.spawn_bullet(1, pos, base_dir.rotated(off), 120.0, {"bullet_color": Color.ORANGE, "is_player_bullet": false, "collision_radius": 8.0})
		"aimed_triple":
			for off in [-0.15, 0.0, 0.15]:
				_game.spawn_bullet(1, pos, base_dir.rotated(off), 120.0, {"bullet_color": Color(0.9, 0.3, 0.3), "is_player_bullet": false, "collision_radius": 8.0})
		"spread_5":
			for i in range(5):
				var a: float = -0.3 + 0.15 * float(i)
				_game.spawn_bullet(1, pos, base_dir.rotated(a), 120.0, {"bullet_color": Color.ORANGE, "is_player_bullet": false, "collision_radius": 8.0})
		"ring_12":
			var step: float = TAU / 12.0
			for i in range(12):
				var d: Vector2 = Vector2.RIGHT.rotated(step * float(i))
				_game.spawn_bullet(1, pos, d, 110.0, {"bullet_color": Color.CYAN, "is_player_bullet": false, "collision_radius": 8.0})
		"ring_16":
			var st: float = TAU / 16.0
			for i in range(16):
				var d: Vector2 = Vector2.RIGHT.rotated(st * float(i))
				_game.spawn_bullet(1, pos, d, 100.0, {"bullet_color": Color.PURPLE, "is_player_bullet": false, "collision_radius": 8.0})
		"spiral_8":
			var t: float = enter_timer * 3.0
			for i in range(8):
				var a: float = TAU * float(i) / 8.0 + t
				_game.spawn_bullet(1, pos, Vector2.RIGHT.rotated(a), 130.0, {"bullet_color": Color.GREEN, "is_player_bullet": false, "collision_radius": 8.0, "angular_velocity": 1.0})
		"fan_aimed":
			for i in range(9):
				var a: float = -0.4 + 0.1 * float(i)
				_game.spawn_bullet(1, pos, base_dir.rotated(a), 110.0, {"bullet_color": Color.PINK, "is_player_bullet": false, "collision_radius": 8.0})
		"double_ring":
			for i in range(18):
				var a: float = TAU * float(i) / 18.0
				_game.spawn_bullet(0, pos, Vector2.RIGHT.rotated(a), 100.0, {"bullet_color": Color.CYAN, "is_player_bullet": false, "collision_radius": 5.0})
				_game.spawn_bullet(1, pos, Vector2.RIGHT.rotated(a + 0.17), 140.0, {"bullet_color": Color.PINK, "is_player_bullet": false, "collision_radius": 8.0})
		_:
			_game.spawn_bullet(1, pos, base_dir, 130.0, {"bullet_color": Color.RED, "is_player_bullet": false, "collision_radius": 8.0})


func take_damage(amount: float) -> void:
	if not is_alive:
		return
	if _damage_cd > 0:
		return
	_damage_cd = damage_cooldown
	var dmg: float = max(amount - defense, 1.0)
	hp -= dmg
	damaged.emit(dmg, hp)
	if _sprite:
		_sprite.modulate = Color(2.0, 2.0, 2.0, 1.0)
		hit_flash_timer = 0.15
	if hp <= 0:
		destroy()


func destroy() -> void:
	if not is_alive:
		return
	is_alive = false
	if _game and _game.has_method("add_score"):
		_game.add_score(score_value)
	var do_drop: bool = randf() < drop_chance
	if _game and do_drop and _game.has_method("add_power") and power_drop > 0:
		_game.add_power(power_drop)
	if do_drop and _game and _game.has_method("get_item_layer"):
		var il: Node2D = _game.get_item_layer()
		if il:
			for i in range(point_item_drops):
				var itype: int = 1  # POINT
				if enemy_id == "elite":
					var rr: float = randf()
					if rr < 0.08: itype = 4  # SHIELD
					elif rr < 0.16: itype = 5  # DRONE
					elif rr < 0.40: itype = 0  # POWER
				var item_scene: PackedScene = load("res://scenes/items/point_item.tscn")
				if item_scene:
					var item: Node2D = item_scene.instantiate()
					item.set("item_type", itype)
					item.global_position = global_position + Vector2(randf_range(-20, 20), randf_range(-10, 10))
					il.add_child(item)
	destroyed.emit(self)
	queue_free()


func _make_placeholder() -> ImageTexture:
	var sz: int = 28
	var img: Image = Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	var cx: float = sz / 2.0
	for x in range(sz):
		for y in range(sz):
			var dist: float = Vector2(float(x) - cx + 0.5, float(y) - cx + 0.5).length()
			if dist <= cx * 0.8:
				img.set_pixel(x, y, color_tint)
			elif dist <= cx:
				img.set_pixel(x, y, Color(color_tint, 0.5))
			else:
				img.set_pixel(x, y, Color.TRANSPARENT)
	return ImageTexture.create_from_image(img)
