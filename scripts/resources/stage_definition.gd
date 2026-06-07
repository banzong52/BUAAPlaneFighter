# StageDefinition.gd
# Resource defining a complete stage — waves, boss, background, BGM
class_name StageDefinition
extends Resource

@export var stage_number: int = 1
@export var stage_name: String = "Stage 1"
@export var bg_texture_layer0: Texture2D
@export var bg_texture_layer1: Texture2D
@export var bg_texture_layer2: Texture2D
@export var bgm_path: String = ""
@export var scroll_speed: float = 60.0
@export var total_duration: float = 180.0  # Seconds before boss
@export var waves: Array[WaveData] = []
@export var midboss_data: Resource
@export var midboss_spawn_time: float = 80.0
@export var boss_data: Resource
@export var boss_name: String = "Unknown Boss"
