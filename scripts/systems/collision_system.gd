# CollisionSystem.gd
# Manual distance-based collision detection — replaces Area2D for performance
# Attach to Game/World node
extends Node2D

## Check enemy bullets against player (hit + graze)
func check_enemy_bullets_vs_player(player: Player, delta: float) -> void:
	if player == null or not player.is_inside_tree():
		return

	var hit_pos := player.get_hitbox_position()
	var hit_radius := player.get_hitbox_radius()
	var graze_radius := player.get_graze_radius()

	var enemy_bullets := BulletPool.get_active_enemy_bullets()
	for bullet in enemy_bullets:
		if not is_instance_valid(bullet):
			continue
		if not bullet.visible:
			continue

		var bullet_radius: float = bullet.get("collision_radius")
		var dist := hit_pos.distance_to(bullet.global_position)

		# Hit check
		if dist < (hit_radius + bullet_radius):
			player.hit_by_bullet(bullet)
			continue  # Don't also count as graze

		# Graze check
		if not bullet.grazed and dist < (graze_radius + bullet_radius):
			bullet.grazed = true
			ScoreManager.add_graze()
			_spawn_graze_effect(bullet.global_position)


## Check player bullets against all active enemies
func check_player_bullets_vs_enemies() -> void:
	var player_bullets := BulletPool.get_active_player_bullets()
	var enemies := WaveController.active_enemies.duplicate()

	for enemy in enemies:
		if not is_instance_valid(enemy) or not enemy.is_alive:
			continue
		var enemy_radius: float = enemy.get("collision_radius")
		var enemy_pos := enemy.global_position

		for bullet in player_bullets:
			if not is_instance_valid(bullet) or not bullet.visible:
				continue
			var bullet_radius: float = bullet.get("collision_radius")
			var dist := enemy_pos.distance_to(bullet.global_position)

			if dist < (enemy_radius + bullet_radius):
				if enemy.has_method("take_damage"):
					var damage: float = bullet.get("damage")
					enemy.take_damage(damage)
				BulletPool.despawn(bullet)
				break  # Each frame, one enemy can be hit by one bullet at most


func _spawn_graze_effect(pos: Vector2) -> void:
	# Simple graze sparkle — could spawn a particle or just flash
	pass


func _process(delta: float) -> void:
	if GameManager.current_state != GameManager.State.PLAYING:
		return

	var player := GameManager.get_player()
	if player:
		check_enemy_bullets_vs_player(player, delta)
	check_player_bullets_vs_enemies()
