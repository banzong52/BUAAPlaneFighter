# EnemyDefinition.gd
# Resource defining an enemy's properties and spawn behavior
class_name EnemyDefinition
extends Resource

@export var enemy_id: String = "fairy"
@export var enemy_name: String = "Fairy"
@export var max_hp: float = 10.0
@export var defense: float = 0.0
@export var score_value: int = 100
@export var power_drop: float = 0.05
@export var point_item_count: int = 1
@export var move_speed: float = 100.0
@export var path_type: int = 0  # PathType enum
@export var path_params: Array[float] = []
@export var fire_interval: float = 1.5
@export var pattern_id: String = "aimed_single"
@export var texture_path: String = ""
@export var collision_radius: float = 12.0
@export var is_boss: bool = false
