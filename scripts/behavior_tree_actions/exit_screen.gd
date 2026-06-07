# ExitScreen.gd
# Beehave action: Move enemy off the screen
extends ActionLeaf

@export var exit_direction: Vector2 = Vector2(0, 1)  # Down
@export var speed: float = 150.0

func tick(actor: Node, _blackboard: Blackboard) -> int:
	if not is_instance_valid(actor):
		return FAILURE

	actor.global_position += exit_direction * speed * actor.get_process_delta_time()

	# Check if offscreen
	var vp_size := actor.get_viewport().get_visible_rect().size
	if (actor.global_position.y > vp_size.y + 100 or
		actor.global_position.y < -200 or
		actor.global_position.x < -200 or
		actor.global_position.x > vp_size.x + 200):
		if actor.has_method("destroy"):
			actor.destroy()
		return SUCCESS

	return RUNNING
