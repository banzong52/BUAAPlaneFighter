# ItemBase.gd — Collectible item
extends Area2D

enum ItemType { POWER, POINT, BOMB_PIECE, LIFE, SHIELD, DRONE }

@export var item_type: int = ItemType.POWER
@export var power_amount: float = 0.05
@export var point_value: int = 100
@export var fall_speed: float = 60.0
@export var magnet_range: float = 80.0
@export var magnet_speed: float = 300.0

var _game: Node = null


func _ready() -> void:
	_game = get_node_or_null("/root/Game")
	body_entered.connect(_on_body_entered)
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 14.0
	collision.shape = shape
	add_child(collision)
	queue_redraw()


func _process(delta: float) -> void:
	if not _game or not _game.has_method("get_state"):
		return
	if _game.get_state() != 1:
		return
	global_position.y += fall_speed * delta
	if not _game or not _game.has_method("get_player"):
		return
	var player: Node2D = _game.get_player()
	if player == null:
		return
	var dist: float = global_position.distance_to(player.global_position)
	if dist < magnet_range:
		var dir: Vector2 = (player.global_position - global_position).normalized()
		global_position += dir * magnet_speed * delta
	if global_position.y > get_viewport().get_visible_rect().size.y + 64:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if not _game or not _game.has_method("get_player"):
		return
	var p: Node2D = _game.get_player()
	if p and p == body:
		_collect()


func _collect() -> void:
	if not _game:
		queue_free()
		return
	match item_type:
		ItemType.POWER:
			if _game.has_method("add_power"):
				_game.add_power(power_amount)
		ItemType.POINT:
			if _game.has_method("add_score"):
				_game.add_score(point_value)
		ItemType.BOMB_PIECE:
			pass
		ItemType.LIFE:
			if "player_hp" in _game:
				_game.player_hp = min(_game.player_hp + 30, _game.player_max_hp)
		ItemType.SHIELD:
			if "shield_layers" in _game:
				_game.set("shield_layers", min(_game.get("shield_layers") + 1, 3))
		ItemType.DRONE:
			if "drone_active" in _game:
				_game.set("drone_active", true)
	queue_free()


func _draw() -> void:
	var color: Color = Color(0.2, 0.9, 0.2)
	match item_type:
		ItemType.POINT: color = Color(0.3, 0.5, 1.0)
		ItemType.BOMB_PIECE: color = Color(1.0, 0.3, 0.1)
		ItemType.LIFE: color = Color(1.0, 0.8, 0.1)
		ItemType.SHIELD: color = Color(0.2, 0.5, 1.0)
		ItemType.DRONE: color = Color(0.0, 0.9, 0.9)
	# Background circle
	draw_circle(Vector2.ZERO, 12.0, Color(color, 0.3))
	draw_circle(Vector2.ZERO, 11.0, color, false, 1.5)
	# Icon per type
	match item_type:
		ItemType.POWER:
			draw_rect(Rect2(-3, -7, 6, 14), Color.WHITE)
			draw_circle(Vector2(0, -7), 2.5, Color.YELLOW)
		ItemType.SHIELD:
			draw_arc(Vector2.ZERO, 8.0, 0.3, TAU - 0.3, 16, Color.WHITE, 2.0)
			draw_rect(Rect2(-1, -3, 2, 6), Color.WHITE)
		ItemType.DRONE:
			draw_rect(Rect2(-1.5, -8, 3, 16), Color.WHITE)
			draw_circle(Vector2(0, -8), 3.0, Color.CYAN)
			draw_rect(Rect2(-5, 2, 10, 3), Color.WHITE)
		ItemType.POINT:
			draw_circle(Vector2.ZERO, 5.0, Color.WHITE)
		ItemType.LIFE:
			draw_rect(Rect2(-6, -1.5, 12, 3), Color.WHITE)
			draw_rect(Rect2(-1.5, -6, 3, 12), Color.WHITE)

func _make_texture() -> ImageTexture:
	var size: int = 24
	var img: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var cx: float = size / 2.0
	var color: Color = Color(0.2, 0.9, 0.2)
	match item_type:
		ItemType.POINT: color = Color(0.3, 0.5, 1.0)
		ItemType.BOMB_PIECE: color = Color(1.0, 0.3, 0.1)
		ItemType.LIFE: color = Color(1.0, 0.8, 0.1)
		ItemType.SHIELD: color = Color(0.2, 0.5, 1.0)
		ItemType.DRONE: color = Color(0.0, 0.9, 0.9)
	for x in range(size):
		for y in range(size):
			var d: float = Vector2(float(x) - cx + 0.5, float(y) - cx + 0.5).length()
			if d <= 8:
				img.set_pixel(x, y, color)
			elif d <= 10:
				img.set_pixel(x, y, Color(color, 0.5))
			else:
				img.set_pixel(x, y, Color.TRANSPARENT)
	return ImageTexture.create_from_image(img)
