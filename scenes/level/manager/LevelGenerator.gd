extends Node3D
class_name LevelGenerator

## ============================================================
## LEVEL GENERATOR
## Génère procéduralement les sections de route avec obstacles et pièces
## ============================================================

# === EXPORTS ===

## Modèles de sections de route disponibles
@export var section_templates: Array[PackedScene] = []

## Nombre de sections à générer au démarrage
@export var initial_sections_count: int = 6

## Nombre de sections sécurisées au début (sans obstacles)
@export var safe_start_sections: int = 1

## Modèles de motifs de pièces (spawnés sur les points de spawn)
@export var pattern_templates: Array[PackedScene] = [
	preload("res://scenes/level/coinspatterns/CoinPatternStraight.tscn"),
	preload("res://scenes/level/coinspatterns/CoinPatternDiagonal.tscn")
]

@export_group("Tuning")

## Distance d'avance pour générer les sections (par rapport au joueur)
@export var spawn_ahead_distance: float = 150.0

## Probabilités de sélection des sections [safe, normal, hard, bonus]
@export var section_weights: Array[float] = [0.30, 0.40, 0.20, 0.10]

## Distance maximale entre deux spawns de motifs de pièces
@export var max_coin_pattern_spacing: float = 20.0

# === VARIABLES ===

## Prochaine position Z où générer une section
var next_spawn_z: float = 0.0

## Liste des sections actives en mémoire
var active_sections: Array[RoadSection] = []

## Référence au joueur
var player: Player = null

# === INITIALIZATION ===

func _ready() -> void:
	# Récupérer la référence du joueur
	_initialize_player_reference()
	
	# Vérifier que les templates sont configurés
	_validate_templates()
	
	# Générer les sections initiales
	_generate_initial_sections()

## Récupère la référence du joueur depuis le groupe "Player"
func _initialize_player_reference() -> void:
	var players := get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		player = players[0] as Player
	else:
		push_warning("LevelGenerator: Aucun joueur trouvé dans le groupe 'Player'")

## Vérifie que les templates sont correctement configurés
func _validate_templates() -> void:
	if section_templates.is_empty():
		push_error("LevelGenerator: Aucun template de section configuré !")
		return
	
	if pattern_templates.is_empty():
		push_warning("LevelGenerator: Aucun template de motif de pièces configuré.")

## Génère les sections initiales (safe + normales)
func _generate_initial_sections() -> void:
	for i in range(initial_sections_count):
		var is_safe := i < safe_start_sections
		spawn_section(is_safe)

# === GAME LOOP ===

## Génère de nouvelles sections quand le joueur avance
func _process(_delta: float) -> void:
	if not player:
		return
	
	# Générer tant que le joueur n'a pas assez de sections devant lui
	while player.global_position.z < next_spawn_z + spawn_ahead_distance:
		spawn_section(false)

# === SECTION SPAWNING ===

## Spawn une nouvelle section de route
## @param force_empty: Si true, spawn une section vide (safe)
func spawn_section(force_empty: bool) -> void:
	# Vérifier que des templates existent
	if section_templates.is_empty():
		push_error("LevelGenerator: Aucun template de section trouvé !")
		return
	
	# Sélectionner un template de section
	var section_scene: PackedScene = _pick_section_scene(force_empty)
	if not section_scene:
		return
	
	# Instancier la section
	var new_section := section_scene.instantiate() as RoadSection
	if not new_section:
		push_error("LevelGenerator: La scène instanciée n'hérite pas de RoadSection !")
		return
	
	# Positionner et ajouter la section
	add_child(new_section)
	new_section.global_position = Vector3(0, 0, next_spawn_z)
	active_sections.append(new_section)
	
	# Spawner les motifs de pièces sur les points de spawn
	_spawn_coin_patterns(new_section)
	
	# Mettre à jour la prochaine position de spawn
	_update_next_spawn_position(new_section)

## Sélectionne un template de section selon les probabilités
## @param force_empty: Force le template sécurisé (index 0)
func _pick_section_scene(force_empty: bool) -> PackedScene:
	if force_empty:
		return section_templates[0]
	
	# Vérifier que les poids sont valides
	var total_weight := 0.0
	for weight in section_weights:
		total_weight += weight
	
	if total_weight <= 0.0:
		push_warning("LevelGenerator: Poids de sélection invalides, utilisation du template par défaut")
		return section_templates[0]
	
	# Sélection aléatoire pondérée
	var random_value := randf() * total_weight
	var cumulative := 0.0
	
	for i in range(min(section_weights.size(), section_templates.size())):
		cumulative += section_weights[i]
		if random_value <= cumulative:
			return section_templates[i]
	
	# Fallback
	return section_templates[0]

## Met à jour la prochaine position de spawn
func _update_next_spawn_position(section: RoadSection) -> void:
	# Essayer d'utiliser le marker EndMarker si disponible
	var end_marker := section.get_node_or_null("EndMarker") as Marker3D
	if end_marker:
		next_spawn_z += end_marker.position.z
	else:
		# Fallback: utiliser la longueur de la section
		next_spawn_z += section.length

# === COIN PATTERNS ===

## Spawn des motifs de pièces sur les points de spawn de la section
func _spawn_coin_patterns(section: RoadSection) -> void:
	if pattern_templates.is_empty():
		return
	
	# Récupérer tous les points de spawn de pièces
	var spawn_points := section.find_children("*", "Marker3D")
	
	# Filtrer les points qui sont dans le groupe "coin_spawn"
	var coin_spawn_points := spawn_points.filter(
		func(point): return point.is_in_group("coin_spawn")
	)
	
	if coin_spawn_points.is_empty():
		return
	
	# Sélectionner un nombre aléatoire de points à utiliser (éviter de surcharger)
	var max_patterns = min(coin_spawn_points.size(), 3)
	var pattern_count := randi_range(1, max_patterns)
	
	# Mélanger les points pour un placement aléatoire
	coin_spawn_points.shuffle()
	
	# Sélectionner les premiers points
	var selected_points := coin_spawn_points.slice(0, pattern_count)
	
	# Spawn un motif sur chaque point sélectionné
	for point in selected_points:
		_spawn_single_pattern(point)

## Spawn un motif de pièces sur un point donné
func _spawn_single_pattern(spawn_point: Marker3D) -> void:
	# Vérifier qu'il n'y a pas déjà un motif sur ce point
	if spawn_point.get_child_count() > 0:
		return
	
	# Sélectionner un motif aléatoire
	var random_pattern_scene = pattern_templates.pick_random()
	if not random_pattern_scene:
		return
	
	# Instancier le motif
	var pattern_instance := random_pattern_scene.instantiate() as Node3D
	if not pattern_instance:
		return
	
	# Ajouter au point de spawn
	spawn_point.add_child(pattern_instance)
	pattern_instance.position = Vector3.ZERO

# === SECTION DESPAWNING ===

## Désactive et supprime une section (appelé par la section elle-même)
## @param section: La section à désactiver
func despawn_section(section: RoadSection) -> void:
	if section in active_sections:
		active_sections.erase(section)

# === DEBUG ===

## Méthode de debug pour visualiser les sections actives
func _debug_print_sections() -> void:
	print("Sections actives: ", active_sections.size())
	for i in range(active_sections.size()):
		var section := active_sections[i]
		print("  [", i, "] ", section.name, " - Z: ", section.global_position.z)

# === HELPER METHODS ===

## Nettoie toutes les sections (utile pour un reset)
func clear_all_sections() -> void:
	for section in active_sections:
		if is_instance_valid(section):
			section.queue_free()
	active_sections.clear()
	next_spawn_z = 0.0

## Régénère le niveau depuis le début
func regenerate_level() -> void:
	clear_all_sections()
	_generate_initial_sections()

# === CLEANUP ===

## Nettoie les sections avant la destruction du générateur
func _exit_tree() -> void:
	for section in active_sections:
		if is_instance_valid(section):
			section.queue_free()
	active_sections.clear()
