extends Node

signal game_over_triggered

var initial_speed := 15.0
var max_speed := 40.0
var acceleration_rate := 0.5

var current_speed := 0.0
var is_game_over := false

func _ready() -> void:
	reset_game()

func _process(delta: float) -> void:
	if not is_game_over and current_speed < max_speed:
		current_speed += acceleration_rate * delta
		current_speed = clamp(current_speed, initial_speed, max_speed)

func trigger_game_over() -> void:
	if is_game_over: return
	
	is_game_over = true
	current_speed = 0.0
	
	game_over_triggered.emit()

func reset_game() -> void:
	current_speed = initial_speed
	is_game_over = false
