extends RoadSection
class_name TunnelSection

@export_group("Tunnel")
@export var obstacle_scene: PackedScene
@export var wave_spacing: float = 20.0
@export var blocked_lanes_per_wave: int = 1

func spawn_objects() -> void:
	if not obstacle_scene:
		push_warning("TunnelSection: obstacle_scene non assigné.")
		return

	var lanes := _get_lane_x_positions()
	if lanes.is_empty():
		push_warning("TunnelSection: aucun SpawnPoint trouvé.")
		return

	var lane_names = lanes.keys()
	var wave_count = int(length / wave_spacing)
	var safe_blocked_count = min(blocked_lanes_per_wave, lane_names.size() - 1)

	for i in range(wave_count):
		var wave_z = -wave_spacing * (i + 1)
		var shuffled = lane_names.duplicate()
		shuffled.shuffle()
		var blocked = shuffled.slice(0, safe_blocked_count)

		for lane_name in blocked:
			var local_pos = Vector3(lanes[lane_name], 0, wave_z)
			spawn_item(obstacle_scene, global_position + local_pos)
