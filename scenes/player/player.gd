extends CharacterBody3D
class_name Player

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@export var lane_distance: float = 3.5
@export var shift_speed: float = 15.0
@export var jump_force: float = 12.0

var current_lane: int = 0
var target_x: float = 0.0

func _ready() -> void:
	add_to_group("Player")
	target_x = 0.0

func _physics_process(delta: float) -> void:
	# Security
	if GameManager.is_game_over:
		if not is_on_floor():
			velocity.y -= gravity * delta
			velocity.z = 0
			move_and_slide()
		return
	
	# Handle Inputs
	if Input.is_action_just_pressed("Left") and current_lane > -1:
		current_lane -= 1
		target_x = current_lane * lane_distance
	
	if Input.is_action_just_pressed("Right") and current_lane < 1:
		current_lane += 1
		target_x = current_lane * lane_distance
	
	# Handle Movement
	global_position.x = lerp(global_position.x, target_x, shift_speed * delta)
	
	# Gravity
	if not is_on_floor():
		velocity.y -= (gravity * 1.5) * delta
	else:
		velocity.y = 0
	
	# Handle Jump
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = jump_force
	
	# Apply movement
	velocity.z = -GameManager.current_speed
	
	velocity.x = 0
	move_and_slide()
