extends Area3D
class_name PowerUp

## ============================================================
## POWER-UP
## Objet collectable qui donne un bonus au joueur
## ============================================================

# === SIGNALS ===

## Émis quand le power-up est collecté
signal powerup_collected(powerup_type: String, duration: float)

# === EXPORTS ===

## Durée du power-up en secondes
@export var duration: float = 10.0

## Son joué lors de la collecte
@export var powerup_sound: AudioStream

## Type de power-up (défini dans la scène enfant)
@export var powerup_type: String = "default"

# === VARIABLES ===

## État de collecte (empêche les doubles appels)
var _collected: bool = false

# === INITIALIZATION ===

func _ready() -> void:
	# Connecter le signal de collision
	body_entered.connect(_on_body_entered)
	
	# Vérifier que SoundManager existe
	if not SoundManager:
		push_warning("PowerUp: SoundManager introuvable !")

# === GAME LOOP ===

## Fait tourner le power-up
func _process(delta: float) -> void:
	rotate_y(deg_to_rad(90.0) * delta)

# === COLLISION ===

## Gère la collecte quand le joueur touche le power-up
func _on_body_entered(body: Node3D) -> void:
	# Vérifier que c'est le joueur
	if not body is Player:
		return
	
	# Empêcher les doubles collectes
	if _collected:
		return
	
	_collected = true
	
	# Jouer le son
	_play_powerup_sound()
	
	# Activer le power-up sur le joueur
	activate_powerup(body)
	
	# Émettre le signal
	powerup_collected.emit(powerup_type, duration)
	
	# Supprimer le power-up
	queue_free()

# === POWER-UP ACTIVATION ===

## Active le power-up sur le joueur (à surcharger dans les classes enfants)
func activate_powerup(_player: Player) -> void:
	pass

# === AUDIO ===

## Joue le son du power-up
func _play_powerup_sound() -> void:
	if not powerup_sound:
		return
	
	if not SoundManager:
		# Fallback: lecture directe
		_play_sound_directly()
		return
	
	# Utiliser SoundManager
	if SoundManager.has_method("play_sfx"):
		SoundManager.play_sfx(powerup_sound, 1.0)
	else:
		_play_sound_directly()

## Lecture directe du son si SoundManager n'est pas disponible
func _play_sound_directly() -> void:
	var audio_player := AudioStreamPlayer3D.new()
	audio_player.stream = powerup_sound
	audio_player.max_distance = 15.0
	audio_player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	
	add_child(audio_player)
	audio_player.play()
	
	# Nettoyer automatiquement après la lecture
	await audio_player.finished
	audio_player.queue_free()

# === VISUAL EFFECTS ===

## Effet de collecte (à surcharger pour des effets personnalisés)
func _play_collect_effect() -> void:
	# Animation de scale (effet "pop")
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector3.ZERO, 0.3).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	
	# Particules (optionnel)
	# var particles := preload("res://particles/powerup_burst.tscn").instantiate()
	# add_child(particles)
	# particles.global_position = global_position

# === RESET ===

## Réinitialise le power-up pour une réutilisation (si utilisé dans un pool)
func reset_powerup() -> void:
	_collected = false
	show()
	scale = Vector3.ONE

# === CLEANUP ===

## Déconnecte les signaux pour éviter les fuites mémoire
func _exit_tree() -> void:
	if body_entered.is_connected(_on_body_entered):
		body_entered.disconnect(_on_body_entered)
