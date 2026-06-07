# PatternDefinition.gd
# Resource defining a bullet pattern configuration
class_name PatternDefinition
extends Resource

enum CurveType { LINEAR, SIN_CURVED, ACCELERATING, DECELERATING }

@export var pattern_id: String = ""
@export var bullet_type: int = 0  # BulletType enum
@export var duration: float = 5.0
@export var interval: float = 0.1
@export var aim_at_player: bool = false
@export var spawn_angle: float = 0.0  # Degrees
@export var angle_spread: float = 0.0
@export var bullet_count: int = 1
@export var rings: int = 1
@export var ring_angle_offset: float = 0.0
@export var spawn_radius: float = 20.0
@export var bullet_speed: float = 200.0
@export var angular_velocity: float = 0.0  # Pattern rotation speed
@export var speed_variation: float = 0.0
@export var curve_type: int = CurveType.LINEAR
@export var color: Color = Color.WHITE
@export var bullet_scale: Vector2 = Vector2(1.0, 1.0)
