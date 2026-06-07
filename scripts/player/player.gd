# Player.gd — 北航一百号 (BUAA-100) 宇宙战机
extends CharacterBody2D

var _game: Node = null
var _sprite: Sprite2D = null


func _ready() -> void:
	_game = get_node_or_null("/root/Game")

	# Player sprite (PNG loaded if imported, else procedural)
	_sprite = Sprite2D.new()
	_sprite.name = "Sprite"
	_sprite.centered = true
	_sprite.scale = Vector2(0.7, 0.7)
	add_child(_sprite)
	if ResourceLoader.exists("res://assets/textures/player/player.png"):
		_sprite.texture = load("res://assets/textures/player/player.png")
	else:
		_sprite.texture = _create_beijing_1_texture()

	# Red hitbox dot — always visible at center
	var dot: Sprite2D = Sprite2D.new()
	dot.name = "HitboxDot"
	dot.centered = true
	dot.z_index = 10
	add_child(dot)
	dot.texture = _create_hitbox_texture()

	# Collision shape for item pickup detection
	var cs: CollisionShape2D = CollisionShape2D.new()
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = 18.0
	cs.shape = circle
	add_child(cs)


func _create_beijing_1_texture() -> ImageTexture:
	var img: Image = Image.create(48, 48, false, Image.FORMAT_RGBA8)
	for x in range(48):
		for y in range(48):
			var cx: float = 24.0; var cy: float = 24.0
			var rx: float = float(x) - cx; var ry: float = float(y) - cy
			# Space fighter: arrow-shaped hull
			var body_w: float = 7.0 - abs(ry) * 0.2
			if abs(rx) < body_w and abs(ry) < 18:
				if ry < -4:
					img.set_pixel(x, y, Color(0.2, 0.4, 0.9, 1.0))
				else:
					img.set_pixel(x, y, Color(0.15, 0.35, 0.85, 1.0))
			# Wings
			elif abs(ry) < 5 and abs(rx) > body_w and abs(rx) < 20:
				var wing_fade: float = 1.0 - (abs(rx) - body_w) / 13.0
				img.set_pixel(x, y, Color(0.3, 0.5, 0.95, wing_fade))
			# Cockpit
			elif abs(rx) < 3 and ry < -10 and ry > -18:
				img.set_pixel(x, y, Color(0.5, 0.8, 1.0, 1.0))
			else:
				img.set_pixel(x, y, Color.TRANSPARENT)
	# Red stripe
	for x in range(10, 38):
		for y in range(18, 22):
			if img.get_pixel(x, y).a > 0:
				img.set_pixel(x, y, Color(0.9, 0.15, 0.15, 1.0))
	# Engine glow
	for x in range(16, 32):
		for y in range(38, 46):
			var dx: float = abs(float(x) - 24.0)
			if dx < 6.0:
				var glow: float = 0.5 + (1.0 - dx / 6.0) * 0.5
				img.set_pixel(x, y, Color(0.2, 0.6, 1.0, glow))
	return ImageTexture.create_from_image(img)


func _create_hitbox_texture() -> ImageTexture:
	var size: int = 16
	var img: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var cx: float = size / 2.0
	for x in range(size):
		for y in range(size):
			var dist: float = Vector2(float(x) - cx + 0.5, float(y) - cx + 0.5).length()
			if dist <= 2.0:
				img.set_pixel(x, y, Color(1.0, 0.0, 0.0, 1.0))
			elif dist <= 4.0:
				img.set_pixel(x, y, Color(1.0, 0.1, 0.1, 0.6))
			else:
				img.set_pixel(x, y, Color.TRANSPARENT)
	return ImageTexture.create_from_image(img)
