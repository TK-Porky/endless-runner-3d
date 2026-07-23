extends Node

# === EXPORTS ===
@export var base_pitch: float = 1.0
@export var pitch_increment: float = 0.05
@export var max_pitch: float = 2.0
@export var combo_duration: float = 1.5
@export var pool_size: int = 5

# === VARIABLES ===
var current_coin_pitch: float = 1.0
var _combo_timer: Timer = null
var _audio_pool: Array[AudioStreamPlayer] = []
var _pool_index: int = 0

# === INITIALIZATION ===
func _ready() -> void:
	# Créer le pool de lecteurs audio comme enfants de l'autoload
	for i in range(pool_size):
		var player := AudioStreamPlayer.new()
		player.name = "AudioPlayer_%d" % i
		player.finished.connect(_on_player_finished.bind(player))
		add_child(player)
		_audio_pool.append(player)
	
	# Créer le timer de combo (désactivé par défaut)
	_combo_timer = Timer.new()
	_combo_timer.name = "ComboTimer"
	_combo_timer.one_shot = true
	_combo_timer.wait_time = combo_duration
	_combo_timer.timeout.connect(_on_combo_timeout)
	add_child(_combo_timer)

# === PUBLIC METHODS ===

## Joue un effet sonore
func play_sfx(stream: AudioStream, pitch: float = 1.0) -> void:
	if not stream:
		push_warning("SoundManager: Tentative de jouer un stream null")
		return
	
	# Trouver un joueur disponible
	var player := _get_available_player()
	if not player:
		push_warning("SoundManager: Aucun joueur audio disponible")
		return
	
	player.stream = stream
	player.pitch_scale = clamp(pitch, 0.01, 4.0)
	player.play()

## Joue un effet de pièce avec pitch progressif (combo)
func play_coin_sfx(stream: AudioStream) -> void:
	play_sfx(stream, current_coin_pitch)
	
	# Incrémenter le pitch
	current_coin_pitch = min(current_coin_pitch + pitch_increment, max_pitch)
	
	# Réinitialiser le timer de combo
	_reset_coin_combo_countdown()

## Réinitialise manuellement le combo
func reset_combo() -> void:
	current_coin_pitch = base_pitch
	if _combo_timer and _combo_timer.is_inside_tree():
		_combo_timer.stop()

## Nettoie tous les sons en cours
func stop_all_sounds() -> void:
	for player in _audio_pool:
		if player.playing:
			player.stop()
		player.stream = null

# === PRIVATE METHODS ===

## Récupère un lecteur audio disponible (round-robin)
func _get_available_player() -> AudioStreamPlayer:
	var player := _audio_pool[_pool_index]
	_pool_index = (_pool_index + 1) % pool_size
	
	# Si le joueur est déjà en train de jouer, on le stoppe
	if player.playing:
		player.stop()
		# Optionnel : log pour debug
		# print("SoundManager: Interruption du player ", _pool_index)
	
	return player

## Gère la fin d'un son
func _on_player_finished(player: AudioStreamPlayer) -> void:
	player.stop()
	player.stream = null

## Réinitialise le compte à rebours du combo
func _reset_coin_combo_countdown() -> void:
	# Arrêter le timer s'il tourne
	if _combo_timer and _combo_timer.is_inside_tree():
		_combo_timer.stop()
	
	# Démarrer le timer
	if _combo_timer:
		_combo_timer.start()

## Callback quand le timer du combo expire
func _on_combo_timeout() -> void:
	current_coin_pitch = base_pitch

# === CLEANUP ===

## Nettoyage propre avant destruction
func _exit_tree() -> void:
	if _combo_timer:
		_combo_timer.timeout.disconnect(_on_combo_timeout)
		_combo_timer.queue_free()
		_combo_timer = null
	
	for player in _audio_pool:
		if player.playing:
			player.stop()
		player.stream = null
		player.finished.disconnect(_on_player_finished)
