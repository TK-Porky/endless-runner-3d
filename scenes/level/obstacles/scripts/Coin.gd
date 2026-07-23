extends Area3D
class_name Coin

## ============================================================
## COIN
## Une pièce collectable qui tourne sur elle-même
## ============================================================

# === EXPORTS ===

## Vitesse de rotation de la pièce (radians par seconde)
@export var rotation_speed: float = 3.0

## Son joué lors de la collecte (optionnel)
@export var coin_sound: AudioStream

# === VARIABLES ===

## État de la pièce (déjà collectée ou non)
var _collected: bool = false

# === INITIALIZATION ===

func _ready() -> void:
	# Connecter le signal de collision avec le corps
	body_entered.connect(_on_body_entered)
	
	# Vérifier que le GameManager existe
	if not GameManager:
		push_warning("Coin: GameManager introuvable ! Assurez-vous qu'il est en autoload.")


# === GAME LOOP ===

## Fait tourner la pièce si elle n'a pas encore été collectée
func _process(delta: float) -> void:
	if not _collected:
		rotate_y(rotation_speed * delta)


# === COLLISION ===

## Gère la collecte quand le joueur touche la pièce
func _on_body_entered(body: Node3D) -> void:
	# Vérifier que le corps est le joueur et que la pièce n'est pas déjà collectée
	if not body.is_in_group("Player"):
		return
	
	if _collected:
		return
	
	# Marquer comme collectée (empêche les doubles appels)
	_collected = true
	
	# Ajouter la pièce au GameManager
	GameManager.collect_coin()
	
	# Jouer le son si disponible
	_play_coin_sound()
	
	# Supprimer la pièce
	queue_free()


# === AUDIO ===

## Joue le son de la pièce si un AudioStream est défini
func _play_coin_sound() -> void:
	if not coin_sound:
		return
	
	if not SoundManager:
		push_warning("Coin: SoundManager introuvable !")
		return
	
	# Vérifier que la méthode existe avant de l'appeler
	if SoundManager.has_method("play_coin_sfx"):
		SoundManager.play_coin_sfx(coin_sound)
	else:
		# Fallback: lecture directe du son
		_play_sound_directly()


## Lecture directe du son si SoundManager n'est pas disponible
func _play_sound_directly() -> void:
	var audio_player := AudioStreamPlayer3D.new()
	audio_player.stream = coin_sound
	audio_player.max_distance = 10.0
	audio_player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	
	add_child(audio_player)
	audio_player.play()
	
	# Nettoyer automatiquement après la lecture
	await audio_player.finished
	audio_player.queue_free()


# === RESET (Optionnel) ===

## Réinitialise la pièce pour une nouvelle utilisation (si réutilisée)
func reset_coin() -> void:
	_collected = false
	show()
