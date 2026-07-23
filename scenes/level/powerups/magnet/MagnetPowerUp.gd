extends PowerUp
class_name MagnetPowerUp

## ============================================================
## MAGNET POWER-UP
## Attire les pièces vers le joueur pendant une durée définie
## ============================================================

# === EXPORTS ===

## Rayon d'attraction du magnet (écrase la valeur du joueur)
@export var magnet_range_override: float = 0.0  # 0 = utilise la valeur du joueur

## Force d'attraction du magnet (écrase la valeur du joueur)
@export var magnet_force_override: float = 0.0  # 0 = utilise la valeur du joueur

# === VARIABLES ===

## Référence au joueur pour appliquer l'effet
var _player: Player = null

# === POWER-UP ACTIVATION ===

## Active le power-up sur le joueur
func activate_powerup(player: Player) -> void:
	_player = player
	
	# Vérifier que GameManager existe
	if not GameManager:
		push_error("MagnetPowerUp: GameManager introuvable !")
		return
	
	# Activer le magnet via GameManager
	_activate_magnet()

## Active le magnet via GameManager
func _activate_magnet() -> void:
	# Vérifier si la méthode existe
	if not GameManager.has_method("activate_magnet"):
		push_error("MagnetPowerUp: GameManager.activate_magnet() n'existe pas !")
		return
	
	# Activer le magnet
	GameManager.activate_magnet(duration)
	
	# Si des overrides sont définis, les appliquer
	if magnet_range_override > 0.0:
		GameManager.magnet_range = magnet_range_override
	
	if magnet_force_override > 0.0:
		GameManager.magnet_force = magnet_force_override

# === AUDIO ===

## Joue un son spécifique pour le magnet (surcharge)
func _play_powerup_sound() -> void:
	# Utiliser le son du power-up parent
	super()

# === CLEANUP ===

## Nettoie les références
func _exit_tree() -> void:
	_player = null
