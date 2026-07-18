extends Node3D
class_name LevelGenerator

# --- CONFIG ---
@export var section_templates: Array[PackedScene] = []
@export var initial_sections_count: int = 6
@export var safe_start_sections: int = 1
@export var pattern_templates: Array[PackedScene] = [
	preload("res://scenes/level/coinspatterns/CoinPatternStraight.tscn"),
	preload("res://scenes/level/coinspatterns/CoinPatternDiagonal.tscn")
]

@export_group("Tuning")
@export var spawn_ahead_distance: float = 150.0

var next_spawn_z: float = 0.0
var active_sections: Array[RoadSection] = []
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
	if not player:
		return
	while player.global_position.z < next_spawn_z + spawn_ahead_distance:
		spawn_section(false)


func spawn_section(force_empty: bool) -> void:
	if section_templates.size() == 0:
		push_error("No (templates) found in the inspector !")
		return

	var section_scene: PackedScene = _pick_section_scene(force_empty)

	var new_section = section_scene.instantiate() as RoadSection
	if not new_section:
		push_error("La scène instanciée n'hérite pas de RoadSection !")
		return

	add_child(new_section)
	new_section.global_position = Vector3(0, 0, next_spawn_z)
	active_sections.append(new_section)

	_spawn_coin_patterns(new_section)

	var end_marker = new_section.get_node_or_null("EndMarker") as Marker3D
	if end_marker:
		next_spawn_z += end_marker.position.z
	else:
		next_spawn_z -= new_section.length


func despawn_section(section: RoadSection) -> void:
	active_sections.erase(section)


func _pick_section_scene(force_empty: bool) -> PackedScene:
	if force_empty:
		return section_templates[0]

	var roll = randf()
	var count = section_templates.size()

	if roll < 0.40 and count > 1:
		# 60% de chance d'avoir la section classique (Aération du rythme)
		return section_templates[1]
	elif roll < 0.70 and count > 2:
		# 30% de chance d'avoir la section de Sauts rythmés
		return section_templates[2]
	elif roll < 0.85 and count > 3:
		# 10% de chance pour le template en position [1]
		return section_templates[3]
	else:
		return section_templates[0]


func _spawn_coin_patterns(section: RoadSection) -> void:
	if pattern_templates.size() == 0:
		return

	var spawn_points = section.find_children("*", "Marker3D")
	for point in spawn_points:
		if point.is_in_group("coin_spawn"):
			var random_pattern_scene = pattern_templates.pick_random()
			var pattern_instance = random_pattern_scene.instantiate() as Node3D
			point.add_child(pattern_instance)
			pattern_instance.position = Vector3.ZERO
