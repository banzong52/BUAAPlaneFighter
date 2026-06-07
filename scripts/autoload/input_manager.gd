# InputManager.gd
# Centralized input handling for the game
extends Node

const FOCUS_SPEED_MULTIPLIER: float = 0.35

## Returns a normalized movement vector (-1 to 1)
func get_move_vector() -> Vector2:
	var input_dir := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)
	return input_dir.normalized() if input_dir.length() > 1.0 else input_dir

## Returns the speed multiplier based on focus state
func get_focus_multiplier() -> float:
	return FOCUS_SPEED_MULTIPLIER if Input.is_action_pressed("focus") else 1.0

## Is the player currently focusing?
func is_focused() -> bool:
	return Input.is_action_pressed("focus")

## Is the shoot button held?
func is_shooting() -> bool:
	return Input.is_action_pressed("shoot")

## Was bomb just pressed?
func is_bomb_just_pressed() -> bool:
	return Input.is_action_just_pressed("bomb")

## Was confirm just pressed?
func is_confirm_just_pressed() -> bool:
	return Input.is_action_just_pressed("shoot") or Input.is_action_just_pressed("focus")
