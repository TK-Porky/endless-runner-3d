extends Camera3D
class_name FollowCamera

## ============================================================
## FOLLOW CAMERA
## Caméra qui suit le joueur avec un décalage et un lissage
## ============================================================

# === EXPORTS ===

## Référence au joueur à suivre (optionnel, sera trouvé automatiquement)
@export var player: Player

## Décalage de la caméra par rapport au joueur
@export var offset := Vector3(0, 3.0, 3.5)

## Vitesse de lissage du suivi (plus élevé = plus réactif)
@export var follow_speed := 15.0

## Activer/Désactiver le regard vers le joueur
@export var look_at_player: bool = false

## Hauteur du point de regard (offset Y pour look_at)
@export var look_offset_y: float = 1.0

# === VARIABLES ===

var _is_initialized: bool = false

# === INITIALIZATION ===

func _ready() -> void:
	# Trouver le joueur si non assigné
	_find_player()
	
	# Positionner la caméra initialement
	_initialize_position()

## Trouve automatiquement le joueur si la référence est manquante
func _find_player() -> void:
	if not player:
		player = get_tree().get_first_node_in_group("Player")
		if not player:
			push_warning("FollowCamera: Aucun joueur trouvé dans le groupe 'Player'")

## Positionne la caméra à la position initiale
func _initialize_position() -> void:
	if not player:
		return
	
	global_position = Vector3(
		0.0,
		player.global_position.y + offset.y,
		player.global_position.z + offset.z
	)
	
	# Regarder vers le joueur si activé
	if look_at_player:
		var look_target := player.global_position + Vector3(0, look_offset_y, 0)
		look_at(look_target, Vector3.UP)
	
	_is_initialized = true

# === GAME LOOP ===

## Suit le joueur avec un lissage sur l'axe Y
func _physics_process(delta: float) -> void:
	# Vérifications de sécurité
	if not _can_follow():
		return
	
	# Calculer la position cible
	var target_position := _calculate_target_position()
	
	# Appliquer le mouvement
	_apply_movement(target_position, delta)
	
	# Orienter la caméra vers le joueur
	if look_at_player:
		_look_at_player()

## Vérifie si la caméra peut suivre le joueur
func _can_follow() -> bool:
	if not player:
		return false
	
	if GameManager.is_game_over:
		return false
	
	if not _is_initialized:
		return false
	
	return true

## Calcule la position cible de la caméra
func _calculate_target_position() -> Vector3:
	return Vector3(
		0.0,  # X toujours centré
		player.global_position.y + offset.y,
		player.global_position.z + offset.z
	)

## Applique le mouvement avec lissage
func _apply_movement(target_position: Vector3, delta: float) -> void:
	# Mouvement sur Z : suivi direct (pas de lissage)
	global_position.z = target_position.z
	
	# Mouvement sur Y : suivi avec lissage (lerp)
	global_position.y = lerp(global_position.y, target_position.y, follow_speed * delta)
	
	# X toujours centré
	global_position.x = 0.0

## Oriente la caméra vers le joueur
func _look_at_player() -> void:
	if not player:
		return
	
	var look_target := player.global_position + Vector3(0, look_offset_y, 0)
	look_at(look_target, Vector3.UP)

# === PUBLIC METHODS ===

## Force la caméra à se repositionner immédiatement
func snap_to_player() -> void:
	if not player:
		return
	
	global_position = Vector3(
		0.0,
		player.global_position.y + offset.y,
		player.global_position.z + offset.z
	)
	
	if look_at_player:
		_look_at_player()
	
	_is_initialized = true

## Met à jour le joueur cible en cours de route
func set_target(new_player: Player) -> void:
	player = new_player
	_initialize_position()

## Change les paramètres de suivi en cours de route
func set_follow_parameters(new_offset: Vector3, new_speed: float) -> void:
	offset = new_offset
	follow_speed = new_speed

# === DEBUG ===

## Méthode de debug pour visualiser le point de regard
func _debug_draw_look_target() -> void:
	if not Engine.is_editor_hint():
		return
	
	if not player:
		return
	
	# var look_target := player.global_position + Vector3(0, look_offset_y, 0)
	# Dessiner un petit gizmo à la position du point de regard
	# (à implémenter avec DebugDraw ou similaire)
