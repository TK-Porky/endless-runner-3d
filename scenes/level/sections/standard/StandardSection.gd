extends RoadSection

@export var obstacles: Array[ObstacleData] = []
@export_range(0.0, 100.0) var empty_chance: float = 40.0

func spawn_objects() -> void:
	if obstacles.is_empty():
		return

	var markers = find_children("*", "Marker3D")
	
	for marker in markers:
		if marker.is_in_group("ObstacleSpawn"):
			
			if randf_range(0.0, 100.0) < empty_chance:
				continue
			
			var selected_scene = _pick_weighted_obstacle()
			if selected_scene:
				spawn_item(selected_scene, marker.global_position)

func _pick_weighted_obstacle() -> PackedScene:
	var total_weight : float = 0.0
	for obstacle in obstacles:
		total_weight += obstacle.weight
		
	var roll = randf_range(0.0, total_weight)
	
	var current_sum : float = 0.0
	for obstacle in obstacles:
		current_sum += obstacle.weight
		if roll <= current_sum:
			return obstacle.scene
			
	return null
