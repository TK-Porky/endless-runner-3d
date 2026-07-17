extends CharacterBody3D
class_name Player

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@export var lane_distance: float = 3.5
@export var shift_speed: float = 15.0
@export var jump_force: float = 12.0

var current_lane: int = 0
var target_x: float = 0.0
var _is_death_animation_played: bool = false

@onready var anim_tree: AnimationTree = $player_visual/AnimationTree
@onready var state_machine = anim_tree["parameters/playback"]
var _current_anim_state: String = ""

@onready var jump_sound: AudioStreamPlayer = $JumpSound
@onready var death_sound: AudioStreamPlayer = $DeathSound

@onready var collision_shape: CollisionShape3D = $CollisionShape3D

var is_sliding := false
var slide_duration := 0.9
var original_height := 2.0
var original_y_pos := 0

func _ready() -> void:
	add_to_group("Player")
	target_x = 0.0
	$player_visual.position.y = -0.73

func _physics_process(delta: float) -> void:
	# Handle Game Over
	if GameManager.is_game_over:
		if not _is_death_animation_played:
			$player_visual.position.y = -0.73
			state_machine.travel("death")
			death_sound.play()
			_is_death_animation_played = true
		
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
	
	# Gravity & Jump Handling
	if not is_on_floor():
		velocity.y -= (gravity * 2.5) * delta
	else:
		velocity.y = 0
	
	# Handle Slide
	if Input.is_action_just_pressed("Down") and is_on_floor() and not is_sliding:
		start_slide()
	
	# Handle Jump
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		if is_sliding:
			$player_visual.position.y = -0.73
			is_sliding = false
		velocity.y = jump_force
		jump_sound.play()
	
	# Handle Animations
	if is_sliding:
		_change_animation_state("sliding")
	elif is_on_floor():
		_change_animation_state("running")
	else:
		if velocity.y > 0.1:
			_change_animation_state("jumping")
		elif velocity.y < -0.1:
			_change_animation_state("falling")
	
	# Apply movement
	velocity.z = -GameManager.current_speed
	
	velocity.x = 0
	move_and_slide()

func start_slide() -> void:
	is_sliding = true
	
	if collision_shape.shape is BoxShape3D:
		collision_shape.shape.size.y = original_height / 2.0
	elif collision_shape.shape is CapsuleShape3D:
		collision_shape.shape.height = original_height / 2.0
	
	collision_shape.position.y = original_y_pos - 0.5 
	$player_visual.position.y = original_y_pos - 0.25 
	
	await get_tree().create_timer(slide_duration).timeout
	
	stop_slide()

func stop_slide() -> void:
	if GameManager.is_game_over: return 
	
	if collision_shape.shape is BoxShape3D:
		collision_shape.shape.size.y = original_height
	elif collision_shape.shape is CapsuleShape3D:
		collision_shape.shape.height = original_height
		
	collision_shape.position.y = original_y_pos
	$player_visual.position.y = -0.73
	
	is_sliding = false

func _change_animation_state(new_state: String) -> void:
	if _current_anim_state != new_state:
		_current_anim_state = new_state
		state_machine.travel(new_state)
