extends Node3D
class_name RoadSection

@export var length: float = 50.0
@export var despawn_buffer: float = 15.0

@export_group("Background")
@export var tree_templates: Array[PackedScene] = []
@export var rock_templates: Array[PackedScene] = []

var player: Player = null
var spawn_points: Array[Marker3D] = []

func _ready() -> void:
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		player = players[0] as Player

	_collect_spawn_points()
	_generate_environment_decor()
	spawn_objects()

func _collect_spawn_points() -> void:
	var container = get_node_or_null("SpawnPoints")
	if not container:
		return
	for child in container.get_children():
		if child is Marker3D:
			spawn_points.append(child)

func spawn_objects() -> void:
	pass

func _generate_environment_decor() -> void:
	var markers = find_children("*", "Marker3D")
	
	for marker in markers:
		if marker.is_in_group("DecorSpawn"):
			
			var random_z_offset = randf_range(-15, 15)
			marker.position.z += random_z_offset
			
			var random_pool = tree_templates if randf() < 0.70 else rock_templates
			
			if random_pool.size() > 0:
				var selected_asset = random_pool.pick_random()
				var item = selected_asset.instantiate() as Node3D
				marker.add_child(item)
				item.position = Vector3.ZERO
				
				item.rotate_y(randf_range(0.0, TAU))
				var random_scale = randf_range(0.7, 1.4)
				item.scale = Vector3(random_scale, random_scale, random_scale)

func _get_lane_x_positions() -> Dictionary:
	var lanes := {}
	for point in spawn_points:
		if "Left" in point.name:
			lanes["left"] = point.position.x
		elif "Center" in point.name:
			lanes["center"] = point.position.x
		elif "Right" in point.name:
			lanes["right"] = point.position.x
	return lanes

func spawn_item(packed_scene: PackedScene, target_global_position: Vector3) -> void:
	var item = packed_scene.instantiate() as Node3D
	add_child(item)
	item.global_position = target_global_position


func _process(_delta: float) -> void:
	if player and player.global_position.z < global_position.z - length - despawn_buffer:
		var generator = get_parent()
		if generator and generator.has_method("despawn_section"):
			generator.despawn_section(self)
		queue_free()
