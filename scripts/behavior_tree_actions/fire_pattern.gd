# FirePattern.gd
# Beehave action: Fire a bullet pattern from the enemy
extends ActionLeaf

@export var pattern_name: String = "aimed_single"
@export var fire_interval: float = 1.5
@export var bullet_count: int = 3

var _timer: float = 0.0
var _shots_fired: int = 0

func before_run(actor: Node, _blackboard: Blackboard) -> void:
	_timer = 0.0
	_shots_fired = 0

func tick(actor: Node, _blackboard: Blackboard) -> int:
	if not is_instance_valid(actor):
		return FAILURE

	_timer -= actor.get_process_delta_time()

	if _timer <= 0:
		_timer = fire_interval
		_shots_fired += 1
		_fire(actor)

		if _shots_fired >= bullet_count:
			return SUCCESS

	return RUNNING


func _fire(actor: Node) -> void:
	var player := GameManager.get_player()
	if player == null:
		return

	var pos := actor.global_position
	var target := player.global_position

	match pattern_name:
		"aimed_single":
			PatternLibrary.fire_aimed(pos, target, 1, 250.0, 0, 0.0)
		"aimed_triple":
			PatternLibrary.fire_aimed(pos, target, 3, 220.0, 0, 20.0)
		"ring":
			PatternLibrary.fire_ring(pos, 12, 200.0, 0.0, 0)
		"spiral":
			PatternLibrary.fire_spiral(pos, 8, 3, 2.0, 180.0, 0)
		_:
			PatternLibrary.fire_aimed(pos, target, 1, 250.0, 0, 0.0)
