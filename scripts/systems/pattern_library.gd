# PatternLibrary.gd
# Factory functions for danmaku bullet patterns
# All functions spawn bullets via BulletPool
extends RefCounted

# Cache the manager reference
static func _pool() -> BulletPoolManager:
	return BulletPool as BulletPoolManager


## Fire bullets aimed at the player
static func fire_aimed(emitter_pos: Vector2, target_pos: Vector2, count: int = 1, speed: float = 250.0,
		bullet_type: int = 0, spread_deg: float = 0.0, color: Color = Color.RED) -> void:
	var base_dir := (target_pos - emitter_pos).normalized()
	var total_spread := deg_to_rad(spread_deg)
	var start_angle := -total_spread / 2.0

	for i in range(count):
		var angle := start_angle + total_spread * i / max(count - 1, 1)
		var dir := base_dir.rotated(angle)
		_pool().spawn(bullet_type, emitter_pos, dir, speed, {
			"bullet_color": color, "is_player_bullet": false
		})


## Fire a fan pattern centered on an angle
static func fire_fan(emitter_pos: Vector2, center_angle_deg: float, spread_deg: float,
		count: int, speed: float = 200.0, bullet_type: int = 0, color: Color = Color.CYAN) -> void:
	var center_dir := Vector2.RIGHT.rotated(deg_to_rad(center_angle_deg))
	var total_spread := deg_to_rad(spread_deg)
	var start_angle := -total_spread / 2.0

	for i in range(count):
		var angle := start_angle + total_spread * i / max(count - 1, 1)
		var dir := center_dir.rotated(angle)
		_pool().spawn(bullet_type, emitter_pos, dir, speed, {
			"bullet_color": color, "is_player_bullet": false
		})


## Fire a ring of evenly-spaced bullets
static func fire_ring(emitter_pos: Vector2, count: int = 12, speed: float = 200.0,
		offset_angle_deg: float = 0.0, bullet_type: int = 0, color: Color = Color.BLUE) -> void:
	var angle_step := TAU / count
	var offset := deg_to_rad(offset_angle_deg)

	for i in range(count):
		var dir := Vector2.RIGHT.rotated(angle_step * i + offset)
		_pool().spawn(bullet_type, emitter_pos, dir, speed, {
			"bullet_color": color, "is_player_bullet": false
		})


## Fire a spiral that evolves over time
static func fire_spiral(emitter_pos: Vector2, count: int = 6, rings: int = 3,
		rotation_speed: float = 1.5, speed: float = 180.0, bullet_type: int = 0, color: Color = Color.GREEN) -> void:
	var time := Time.get_ticks_msec() / 1000.0
	var angle_step := TAU / count

	for r in range(rings):
		var ring_speed := speed * (1.0 + r * 0.15)
		for i in range(count):
			var angle := angle_step * i + time * rotation_speed + r * (TAU / (count * rings))
			var dir := Vector2.RIGHT.rotated(angle)
			_pool().spawn(bullet_type, emitter_pos, dir, ring_speed, {
				"bullet_color": color, "is_player_bullet": false
			})


## Fire a random spray
static func fire_random_spread(emitter_pos: Vector2, target_pos: Vector2, count: int = 10,
		spread_deg: float = 45.0, speed: float = 220.0, bullet_type: int = 0, color: Color = Color.ORANGE) -> void:
	var base_dir := (target_pos - emitter_pos).normalized()
	var spread_rad := deg_to_rad(spread_deg)

	for i in range(count):
		var angle := randf_range(-spread_rad, spread_rad)
		var dir := base_dir.rotated(angle)
		var spd := speed * randf_range(0.8, 1.2)
		_pool().spawn(bullet_type, emitter_pos, dir, spd, {
			"bullet_color": color, "is_player_bullet": false
		})


## Fire a burst of bullets from multiple emitters
static func fire_burst(emitter_positions: Array[Vector2], bullet_type: int = 0,
		speed: float = 180.0, color: Color = Color.PURPLE) -> void:
	for pos in emitter_positions:
		for i in range(8):
			var dir := Vector2.RIGHT.rotated(TAU * i / 8.0)
			_pool().spawn(bullet_type, pos, dir, speed, {
				"bullet_color": color, "is_player_bullet": false
			})


## Fire a wall — horizontal line of bullets moving in a direction
static func fire_wall(emitter_pos: Vector2, wall_direction: Vector2, bullet_direction: Vector2,
		count: int = 20, spacing: float = 16.0, speed: float = 150.0, bullet_type: int = 0,
		color: Color = Color.WHITE) -> void:
	var perpendicular := Vector2(-wall_direction.y, wall_direction.x)
	var start_offset := perpendicular * (spacing * count / 2.0)

	for i in range(count):
		var pos := emitter_pos + perpendicular * (spacing * i) - start_offset
		_pool().spawn(bullet_type, pos, bullet_direction.normalized(), speed, {
			"bullet_color": color, "is_player_bullet": false
		})


## Fire a complex spell-card style pattern combining multiple rings
static func fire_flower(emitter_pos: Vector2, petals: int = 6, layers: int = 3,
		speed: float = 200.0, color: Color = Color.HOT_PINK) -> void:
	for layer in range(layers):
		var layer_speed := speed * (1.0 + layer * 0.1)
		var offset := TAU * layer / (petals * layers)
		for i in range(petals):
			var angle := TAU * i / petals + offset
			var dir := Vector2.RIGHT.rotated(angle)
			var spawn_pos := emitter_pos + dir * 20.0
			_pool().spawn(0, spawn_pos, dir, layer_speed, {
				"bullet_color": color, "is_player_bullet": false
			})
