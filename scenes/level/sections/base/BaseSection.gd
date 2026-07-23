extends Node3D
class_name RoadSection

## ============================================================
## ROAD SECTION
## Une section de route générée procéduralement avec décorations
## ============================================================

# === EXPORTS ===

## Longueur de la section (distance avant désactivation)
@export var length: float = 50.0

## Marge avant désactivation (buffer avant de supprimer la section)
@export var despawn_buffer: float = 15.0

@export_group("Environment")
## Modèles d'arbres à instancier sur la section
@export var tree_templates: Array[PackedScene] = []
## Modèles de rochers à instancier sur la section
@export var rock_templates: Array[PackedScene] = []

# === VARIABLES ===

var player: Player = null
var spawn_points: Array[Marker3D] = []

# === INITIALIZATION ===

func _ready() -> void:
	# Récupérer la référence du joueur
	_initialize_player_reference()
	
	# Configurer la section
	_collect_spawn_points()
	_generate_environment_decor()
	
	# Surcharger cette fonction pour spawner des obstacles
	spawn_objects()


## Récupère la référence du joueur depuis le groupe "Player"
func _initialize_player_reference() -> void:
	var players := get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		player = players[0] as Player
	else:
		push_warning("RoadSection: Aucun joueur trouvé dans le groupe 'Player'")

## Collecte tous les points de spawn (Markers) dans le nœud "SpawnPoints"
func _collect_spawn_points() -> void:
	var container := get_node_or_null("SpawnPoints")
	if not container:
		return
	
	for child in container.get_children():
		if child is Marker3D:
			spawn_points.append(child)

## Surcharger cette fonction pour spawner des obstacles/power-ups
func spawn_objects() -> void:
	# À surcharger dans les classes enfants
	pass

## Génère la décoration environnementale (arbres, rochers)
func _generate_environment_decor() -> void:
	var markers := find_children("*", "Marker3D")
	
	for marker in markers:
		# Vérifier si le marker est un point de décoration
		if not marker.is_in_group("DecorSpawn"):
			continue
		
		# Décalage aléatoire sur l'axe Z pour varier les positions
		var random_z_offset := randf_range(-15.0, 15.0)
		marker.position.z += random_z_offset
		
		# Sélectionner un pool aléatoire (70% arbres, 30% rochers)
		var random_pool: Array[PackedScene]
		if randf() < 0.70:
			random_pool = tree_templates
		else:
			random_pool = rock_templates
		
		# Instancier un élément décoratif
		_instantiate_decor_item(marker, random_pool)


## Instancie un élément décoratif à la position du marker
func _instantiate_decor_item(marker: Marker3D, pool: Array[PackedScene]) -> void:
	if pool.is_empty():
		return
	
	# Sélectionner un modèle aléatoire du pool
	var selected_asset = pool.pick_random()
	var item := selected_asset.instantiate() as Node3D
	
	if not item:
		push_error("RoadSection: Impossible d'instancier l'élément décoratif")
		return
	
	# Ajouter l'élément comme enfant du marker
	marker.add_child(item)
	item.position = Vector3.ZERO
	
	# Appliquer des transformations aléatoires
	item.rotate_y(randf_range(0.0, TAU))  # Rotation aléatoire
	var random_scale := randf_range(0.7, 1.4)
	item.scale = Vector3(random_scale, random_scale, random_scale)


## Récupère les positions X des voies (gauche, centre, droite)
func _get_lane_x_positions() -> Dictionary:
	var lanes := {}
	for point in spawn_points:
		var point_name := point.name
		if "Left" in point_name:
			lanes["left"] = point.position.x
		elif "Center" in point_name:
			lanes["center"] = point.position.x
		elif "Right" in point_name:
			lanes["right"] = point.position.x
	return lanes


## Spawn un objet à une position globale donnée
func spawn_item(packed_scene: PackedScene, target_global_position: Vector3) -> void:
	if not packed_scene:
		push_error("RoadSection: Tentative de spawn avec un PackedScene null")
		return
	
	var item := packed_scene.instantiate() as Node3D
	if not item:
		push_error("RoadSection: Impossible d'instancier l'objet")
		return
	
	add_child(item)
	item.global_position = target_global_position


# === LIFE CYCLE ===

## Vérifie si la section doit être désactivée (quand le joueur est passé)
func _process(_delta: float) -> void:
	# Vérifier que le joueur existe et est suffisamment loin
	if not player:
		return
	
	var player_distance := player.global_position.z
	var section_end_z := global_position.z - length - despawn_buffer
	
	# Si le joueur a dépassé la section, la supprimer
	if player_distance < section_end_z:
		var generator := get_parent()
		if generator and generator.has_method("despawn_section"):
			generator.despawn_section(self)
		queue_free()
