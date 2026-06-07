# WaveData.gd
# Resource defining a single enemy wave
class_name WaveData
extends Resource

enum ClearCondition { ALL_DESTROYED, TIMER, BOSS_TRIGGERED }

@export var spawn_time: float = 0.0
@export var enemies: Array = []  # Array of enemy spawn definitions
@export var clear_condition: int = ClearCondition.ALL_DESTROYED
@export var clear_timer: float = 0.0
