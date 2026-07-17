extends Camera3D
class_name FollowCamera

@export var player: Player

@export var offset := Vector3(0, 3.0, 3.5)

@export var follow_speed := 15.0

func _ready() -> void:
	if not player:
		player = get_tree().get_first_node_in_group("Player")
	
	if player:
		global_position = Vector3(
			0,
			player.global_position.y + offset.y,
			player.global_position.z + offset.z
		)

func _physics_process(delta: float) -> void:
	if not player or GameManager.is_game_over:
		return

	var target_position = Vector3(
		0, 
		player.global_position.y + offset.y,
		player.global_position.z + offset.z
	)
	
	global_position.z = player.global_position.z + offset.z
	global_position.y = lerp(global_position.y, target_position.y, follow_speed * delta)
	
	global_position.x = 0
	
	#var look_target = player.global_position + Vector3(0, 1.0, 0)
	#look_at(look_target, Vector3.UP)
