# BulletPool.gd
# Object pool for all bullet types — manages spawn/despawn lifecycle
extends Node

class_name BulletPoolManager

const POOL_SIZE_PER_TYPE: int = 500
const OVERFLOW_LIMIT: int = 3000

# Maps BulletType enum value -> Array[Node2D] of inactive bullets
var _pools: Dictionary = {}
# Array of all currently active bullets
var _active_bullets: Array[Node2D] = []
# Cached bullet scene
var _bullet_scene: PackedScene = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_bullet_scene = load("res://scenes/bullets/bullet_base.tscn") if ResourceLoader.exists("res://scenes/bullets/bullet_base.tscn") else null

func _process(delta: float) -> void:
	if GameManager.current_state != GameManager.State.PLAYING:
		return
	# Update all active bullets
	for bullet in _active_bullets:
		if is_instance_valid(bullet) and bullet.has_method("update_bullet"):
			bullet.update_bullet(delta)

func spawn(bullet_type: int, pos: Vector2, direction: Vector2, speed: float, config: Dictionary = {}) -> Node2D:
	if _bullet_scene == null:
		return null

	var pool_key := bullet_type
	if not _pools.has(pool_key):
		_pools[pool_key] = []

	var pool: Array = _pools[pool_key]
	var bullet: Node2D = null

	if pool.size() > 0:
		bullet = pool.pop_back()
	else:
		# Check overflow
		if _active_bullets.size() >= OVERFLOW_LIMIT:
			# Reuse oldest active bullet of same type
			for b in _active_bullets:
				if is_instance_valid(b) and b.get("bullet_type") == bullet_type:
					bullet = b
					_active_bullets.erase(b)
					break
			if bullet == null:
				return null  # Can't spawn
		else:
			bullet = _bullet_scene.instantiate()
			if bullet == null:
				return null

	# Initialize bullet
	bullet.global_position = pos
	bullet.set("bullet_type", bullet_type)
	bullet.set("direction", direction)
	bullet.set("speed", speed)
	bullet.set("age", 0.0)
	bullet.set("grazed", false)
	bullet.visible = true
	bullet.process_mode = Node.PROCESS_MODE_INHERIT

	# Apply extra config
	for key in config:
		bullet.set(key, config[key])

	# Add to world
	var world := _get_bullet_layer()
	if world:
		world.add_child(bullet)

	_active_bullets.append(bullet)
	return bullet

func despawn(bullet: Node2D) -> void:
	if not is_instance_valid(bullet):
		return

	_active_bullets.erase(bullet)

	var bullet_type = bullet.get("bullet_type")
	var pool_key = bullet_type if bullet_type != null else 0
	if not _pools.has(pool_key):
		_pools[pool_key] = []

	# Reset state
	bullet.visible = false
	bullet.process_mode = Node.PROCESS_MODE_DISABLED
	if bullet.has_method("reset_state"):
		bullet.reset_state()

	# Remove from scene
	if bullet.get_parent():
		bullet.get_parent().remove_child(bullet)

	_pools[pool_key].append(bullet)

func despawn_all_enemy_bullets() -> void:
	var bullets_to_despawn: Array[Node2D] = []
	for bullet in _active_bullets:
		if is_instance_valid(bullet) and not bullet.get("is_player_bullet"):
			bullets_to_despawn.append(bullet)
	for bullet in bullets_to_despawn:
		despawn(bullet)

func despawn_all() -> void:
	var bullets_to_despawn := _active_bullets.duplicate()
	for bullet in bullets_to_despawn:
		despawn(bullet)

func get_active_enemy_bullets() -> Array[Node2D]:
	var result: Array[Node2D] = []
	for bullet in _active_bullets:
		if is_instance_valid(bullet) and not bullet.get("is_player_bullet"):
			result.append(bullet)
	return result

func get_active_player_bullets() -> Array[Node2D]:
	var result: Array[Node2D] = []
	for bullet in _active_bullets:
		if is_instance_valid(bullet) and bullet.get("is_player_bullet"):
			result.append(bullet)
	return result

func get_active_count() -> int:
	return _active_bullets.size()

func _get_bullet_layer() -> Node2D:
	var root := get_tree().get_first_node_in_group("bullet_layer")
	if root:
		return root
	# Fallback: find in game scene
	if GameManager.game_scene:
		var world := GameManager.game_scene.get_node_or_null("World")
		if world:
			return world.get_node_or_null("BulletLayer")
	return null
