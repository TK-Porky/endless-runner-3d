extends RoadSection
class_name SlalomSection

@export_group("Slalom")
@export var obstacle_scene: PackedScene
@export var wave_spacing: float = 15.0


func spawn_objects() -> void:
	if not obstacle_scene:
		push_warning("SlalomSection: obstacle_scene non assigné.")
		return

	var lanes := _get_lane_x_positions()
	if not (lanes.has("left") and lanes.has("center") and lanes.has("right")):
		push_warning("SlalomSection: nécessite les 3 voies Left/Center/Right.")
		return

	var wave_count = int(length / wave_spacing)
	var open_lane_sequence = ["left", "right"]  # jamais "center": on veut un vrai zigzag

	for i in range(wave_count):
		var z = -wave_spacing * (i + 1)
		var open_lane = open_lane_sequence[i % open_lane_sequence.size()]

		for lane_name in lanes.keys():
			if lane_name != open_lane:
				spawn_item(obstacle_scene, global_position + Vector3(lanes[lane_name], 0, z))
