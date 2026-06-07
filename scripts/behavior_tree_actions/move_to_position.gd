# MoveToPosition.gd
# Beehave action: Move enemy to a target position
extends ActionLeaf

@export var target_x: float = 0.0
@export var target_y: float = 200.0
@export var speed: float = 100.0

func tick(actor: Node, _blackboard: Blackboard) -> int:
	if not is_instance_valid(actor):
		return FAILURE

	var target := Vector2(target_x, target_y)
	if target_x == 0.0:
		target.x = actor.global_position.x

	var current := actor.global_position
	var dir := (target - current).normalized()
	var dist := current.distance_to(target)

	if dist < 5.0:
		return SUCCESS

	actor.global_position += dir * speed * actor.get_process_delta_time()
	return RUNNING
