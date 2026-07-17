extends RoadSection
class_name JumpSection

@export_group("Jump")
@export var jump_obstacle_scene: PackedScene
@export var rhythm_spacing: float = 12.0
@export var lane_variation: bool = true


func spawn_objects() -> void:
	if not jump_obstacle_scene:
		push_warning("JumpSection_Rhythmic: jump_obstacle_scene non assigné.")
		return

	var lanes := _get_lane_x_positions()
	var lane_names = lanes.keys()
	var obstacle_count = int(length / rhythm_spacing)

	for i in range(obstacle_count):
		var z = -rhythm_spacing * (i + 1)
		var x = 0.0
		if lane_variation and lane_names.size() > 0:
			x = lanes[lane_names.pick_random()]
		spawn_item(jump_obstacle_scene, global_position + Vector3(x, 0, z))
