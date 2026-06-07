# ResourceManager.gd
# Preloads and caches all game resources
extends Node

var _texture_cache: Dictionary = {}
var _scene_cache: Dictionary = {}
var _stage_data_cache: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func preload_all() -> void:
	# Called during loading screen
	pass

func get_texture(path: String) -> Texture2D:
	if not _texture_cache.has(path):
		if ResourceLoader.exists(path):
			_texture_cache[path] = load(path)
		else:
			return null
	return _texture_cache[path]

func get_scene(path: String) -> PackedScene:
	if not _scene_cache.has(path):
		if ResourceLoader.exists(path):
			_scene_cache[path] = load(path)
		else:
			return null
	return _scene_cache[path]

func get_stage_data(stage_num: int) -> Resource:
	var path := "res://resources/stages/stage_%d.tres" % stage_num
	if not _stage_data_cache.has(path):
		if ResourceLoader.exists(path):
			_stage_data_cache[path] = load(path)
		else:
			return null
	return _stage_data_cache[path]

func clear_cache() -> void:
	_texture_cache.clear()
	_scene_cache.clear()
	_stage_data_cache.clear()
