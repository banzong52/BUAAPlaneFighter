# BulletBase.gd — Bullet managed by Game node's pool
extends Node2D

@export var bullet_type: int = 0
@export var is_player_bullet: bool = false

var direction: Vector2 = Vector2.DOWN
var speed: float = 200.0
var angular_velocity: float = 0.0
var acceleration: float = 0.0
var max_speed: float = 600.0
var lifetime: float = 20.0
var age: float = 0.0
var damage: float = 1.0
var collision_radius: float = 4.0
var grazed: bool = false
var bullet_color: Color = Color.WHITE

const OFFSCREEN_MARGIN: float = 64.0

var _game: Node = null


func _ready() -> void:
	_game = get_node_or_null("/root/Game")
	# Don't set visibility here — pool manager controls it


func update_bullet(delta: float) -> void:
	age += delta
	if angular_velocity != 0.0:
		direction = direction.rotated(angular_velocity * delta)
	if acceleration != 0.0:
		speed = min(speed + acceleration * delta, max_speed)
	global_position += direction * speed * delta
	if is_offscreen() or age >= lifetime:
		if _game and _game.has_method("despawn_bullet"):
			_game.despawn_bullet(self)
		return
	queue_redraw()


func is_offscreen() -> bool:
	var vp: Vector2 = get_viewport().get_visible_rect().size
	return (global_position.x < -OFFSCREEN_MARGIN or
		global_position.x > vp.x + OFFSCREEN_MARGIN or
		global_position.y < -OFFSCREEN_MARGIN or
		global_position.y > vp.y + OFFSCREEN_MARGIN)


func reset_state() -> void:
	direction = Vector2.DOWN
	speed = 200.0
	angular_velocity = 0.0
	acceleration = 0.0
	max_speed = 600.0
	lifetime = 20.0
	age = 0.0
	damage = 1.0
	collision_radius = 4.0
	grazed = false
	bullet_color = Color.WHITE


func _draw() -> void:
	match bullet_type:
		0:
			draw_circle(Vector2.ZERO, 4.0, bullet_color)
		1:
			draw_circle(Vector2.ZERO, 8.0, bullet_color)
			draw_circle(Vector2.ZERO, 8.0, Color(1,1,1,0.6), false, 1.5)
		2:
			draw_rect(Rect2(-3, -8, 6, 12), bullet_color)
		3:
			draw_circle(Vector2.ZERO, 10.0, Color(bullet_color, 0.3))
		4:
			_draw_star(6, 5.0, 8.0, bullet_color)
		8:
			draw_circle(Vector2.ZERO, 3.0, Color.YELLOW)
		9:
			draw_rect(Rect2(-3, -8, 6, 16), Color.ORANGE_RED)
			draw_circle(Vector2(0, -8), 2, Color.YELLOW)
		_:
			draw_circle(Vector2.ZERO, 3.0, Color.WHITE)


func _draw_star(pts: int, ir: float, or_: float, color: Color) -> void:
	var step: float = TAU / float(pts * 2)
	var arr := PackedVector2Array()
	for i in range(pts * 2):
		var r: float = or_ if i % 2 == 0 else ir
		var a: float = step * float(i) - TAU / 4.0
		arr.append(Vector2(cos(a), sin(a)) * r)
	draw_colored_polygon(arr, color)
