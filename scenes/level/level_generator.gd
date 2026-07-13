extends Node3D

# --- CONFIG ---
@export var section_templates: Array[PackedScene] = []

@export var initial_sections_count: int = 6
@export var safe_start_sections: int = 2

var next_spawn_z: float = 0.0

var active_sections: Array[Node3D] = []

var player: Player = null

func _ready() -> void:
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		player = players[0]
	
	for i in range(initial_sections_count):
		if i < safe_start_sections:
			spawn_section(true)
		else:
			spawn_section(false)

func _process(_delta: float) -> void:
	if player:
		if player.global_position.z < next_spawn_z + 150.0:
			spawn_section(false)

func spawn_section(force_empty: bool) -> void:
	if section_templates.size() == 0:
		push_error("No (templates) found in the inspector !")
		return

	var section_scene: PackedScene
	
	if force_empty:
		section_scene = section_templates[0]
	else:
		var random_index = randi() % section_templates.size()
		section_scene = section_templates[random_index]

	var new_section = section_scene.instantiate() as Node3D
	
	new_section.global_position = Vector3(0, 0, next_spawn_z)
	
	add_child(new_section)
	
	var end_marker = new_section.get_node("EndMarker") as Marker3D
	if end_marker:
		next_spawn_z += end_marker.position.z
	else:
		next_spawn_z -= 50.0
