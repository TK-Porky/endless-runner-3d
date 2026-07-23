extends CharacterBody3D
class_name Player

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@export var lane_distance: float = 3.5
@export var shift_speed: float = 15.0
@export var jump_force: float = 12.0

@export var magnet_range: float = 15.0
@export var magnet_force: float = 50.0

var current_lane: int = 0
var target_x: float = 0.0
var _is_death_animation_played: bool = false

@onready var anim_tree: AnimationTree = $player_visual/AnimationTree
@onready var state_machine = anim_tree["parameters/playback"]
var _current_anim_state: String = ""

@onready var jump_sound: AudioStreamPlayer = $JumpSound
@onready var death_sound: AudioStreamPlayer = $DeathSound

@onready var collision_shape: CollisionShape3D = $CollisionShape3D

@export var has_shield: bool = false
@onready var shield_visual: Node3D = $shield_visual
@onready var shield_hit_sound: AudioStreamPlayer = $ShieldHitSound

var is_sliding := false
var slide_duration := 0.9
var original_height := 2.0
var original_y_pos := 0

var _is_jump_cancelling: bool = false
var _slide_timer: SceneTreeTimer = null

@onready var magnet_visual: Node3D = $magnet_visual

func _ready() -> void:
	add_to_group("Player")
	target_x = 0.0
	$player_visual.position.y = -0.73
	if shield_visual:
		shield_visual.visible = false
	if magnet_visual:
		magnet_visual.visible = false

func _physics_process(delta: float) -> void:
	# Handle Game Over
	if GameManager.is_game_over:
		die()
		
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
	var speed_ratio: float = GameManager.current_speed / 12.0
	var dynamic_gravity = (gravity * 2.5) * speed_ratio
	
	# === Gravity ===
	if not is_on_floor():
		# Si on est en jump-cancel, gravité augmentée pour retomber plus vite
		var gravity_multiplier := 1.0
		if _is_jump_cancelling:
			gravity_multiplier = 2.5
		
		velocity.y -= dynamic_gravity * gravity_multiplier * delta
	else:
		velocity.y = 0
		_is_jump_cancelling = false
	
	# Handle Slide - Démarrer un slide depuis le sol
	if Input.is_action_just_pressed("Down") and is_on_floor() and not is_sliding:
		start_slide()
	
	# === Jump-Cancel - Appuyer sur Down en l'air ===
	if Input.is_action_just_pressed("Down") and not is_on_floor() and not is_sliding:
		_cancel_jump()
		start_slide()
	
	# Handle Jump - Slide-Cancel existant
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		if is_sliding:
			$player_visual.position.y = -0.73
			is_sliding = false
		
		velocity.y = jump_force * sqrt(speed_ratio)
		jump_sound.play()
	
	# Handle Magnet
	if GameManager.is_magnet_active:
		_attract_coins()
		magnet_visual.show()
	else:
		magnet_visual.hide()
	
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
	
	_slide_timer = get_tree().create_timer(slide_duration)
	await _slide_timer.timeout
	
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
	_slide_timer = null

func _cancel_jump() -> void:
	_is_jump_cancelling = true
	velocity.y = -jump_force * 1.7 + gravity

func activate_shield() -> void:
	has_shield = true
	if shield_visual:
		shield_visual.visible = true

func hit_obstacle() -> void:
	if has_shield:
		has_shield = false
		shield_hit_sound.play()
		if shield_visual:
			shield_visual.visible = false
	else:
		GameManager.trigger_game_over()
		die()

## Attire les pièces vers le joueur
func _attract_coins() -> void:
	# Récupérer toutes les pièces dans la scène
	var coins : Array[Node]= get_tree().get_nodes_in_group("Coins")
	
	for coin in coins:
		if not coin is Coin:
			continue
		
		var coin_pos : Vector3 = coin.global_position
		var player_pos := global_position
		var distance := player_pos.distance_to(coin_pos)
		
		# Vérifier si la pièce est dans la range
		if distance <= magnet_range and distance > 0.5:
			# Calculer la direction et la force
			var direction := (player_pos - coin_pos).normalized()
			var distance_factor := 1.0 - (distance / magnet_range)
			var force : float = magnet_force * max(distance_factor, 0.1)
			
			# Attirer la pièce
			coin.global_position += direction * force * get_process_delta_time()

func die() -> void:
	if not _is_death_animation_played:
		$player_visual.position.y = -0.73
		state_machine.travel("death")
		death_sound.play()
		_is_death_animation_played = true

func _change_animation_state(new_state: String) -> void:
	if _current_anim_state != new_state:
		_current_anim_state = new_state
		state_machine.travel(new_state)
