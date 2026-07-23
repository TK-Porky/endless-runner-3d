extends Node

# === SIGNALS ===
signal game_over_triggered
signal score_updated(new_score: int)
signal coins_updated(run_coins: int)
signal total_coins_updated(total_coins: int)
signal multiplier_updated(new_multiplier: float)
signal power_up_activated(duration: float, powerup_label: String)

# === EXPORTS ===
@export var initial_speed: float = 15.0
@export var max_speed: float = 40.0
@export var acceleration_rate: float = 0.2

# === VARIABLES ===
var current_speed: float = 0.0
var is_game_over: bool = false
var current_score: float = 0.0
var score_multiplier: float = 1.0
var current_run_coins: int = 0
var total_coins: int = 0
var high_score: int = 0

# === CONSTANTS ===
const SAVE_PATH: String = "user://save_data.cfg"
const MAX_SCORE_MULTIPLIER: float = 10.0

# === PRIVATE VARIABLES ===
var _multiplier_timer: Timer = null
var _magnet_timer: Timer = null

# === POWER-UP STATES VARIABLES ===
var is_magnet_active: bool = false

# === INITIALIZATION ===
func _ready() -> void:
	# Créer le timer du multiplicateur
	_multiplier_timer = Timer.new()
	_multiplier_timer.name = "MultiplierTimer"
	_multiplier_timer.one_shot = true
	_multiplier_timer.timeout.connect(_on_multiplier_timeout)
	add_child(_multiplier_timer)
	
	# Créer le timer de l'aimant
	_magnet_timer = Timer.new()
	_magnet_timer.name = "MagnetTimer"
	_magnet_timer.one_shot = true
	_magnet_timer.timeout.connect(_on_magnet_timeout)
	add_child(_magnet_timer)
	
	load_data()
	reset_game()

func _process(delta: float) -> void:
	if not is_game_over:
		# Accélération progressive
		if current_speed < max_speed:
			current_speed += acceleration_rate * delta
			current_speed = clamp(current_speed, initial_speed, max_speed)
		
		# Mise à jour du score (avec multiplicateur)
		current_score += current_speed * delta * score_multiplier
		score_updated.emit(int(current_score))

# === PUBLIC METHODS ===

## Ajoute du score directement
func add_score(amount: int) -> void:
	if not is_game_over and amount > 0:
		current_score += amount * score_multiplier
		score_updated.emit(int(current_score))

## Active un multiplicateur de score
func activate_score_multiplier(multiplier: float = 2.0, duration: float = 5.0) -> void:
	if is_game_over:
		return
	
	# Valider les paramètres
	multiplier = clamp(multiplier, 1.0, MAX_SCORE_MULTIPLIER)
	duration = max(duration, 0.5)
	
	# Arrêter l'ancien timer s'il tourne
	if _multiplier_timer and _multiplier_timer.is_inside_tree():
		_multiplier_timer.stop()
	
	# Appliquer le nouveau multiplicateur
	score_multiplier = multiplier
	multiplier_updated.emit(score_multiplier)
	power_up_activated.emit(duration, "Multiplier")
	
	# Démarrer le timer
	_multiplier_timer.wait_time = duration
	_multiplier_timer.start()

## Active un aimant à pieces
func activate_magnet(duration: float = 5.0) -> void:
	if is_game_over:
		return
	
	# Valider les paramètres
	duration = max(duration, 0.5)
	
	# Arrêter l'ancien timer
	if _magnet_timer and _magnet_timer.is_inside_tree():
		_magnet_timer.stop()
	
	# Appliquer le nouveau multiplicateur
	is_magnet_active = true
	power_up_activated.emit(duration, "Magnet")
	
	# Démarrer le timer
	_magnet_timer.wait_time = duration
	_magnet_timer.start()

## Déclenche le game over
func trigger_game_over() -> void:
	if is_game_over:
		return
	
	is_game_over = true
	current_speed = 0.0
	
	# Arrêter le multiplicateur
	if _multiplier_timer and _multiplier_timer.is_inside_tree():
		_multiplier_timer.stop()
	score_multiplier = 1.0
	
	# Ajouter les pièces de la run au total
	total_coins += current_run_coins
	total_coins_updated.emit(total_coins)
	
	# Vérifier le high score
	check_new_highscore()
	
	# Sauvegarder uniquement au Game Over
	save_data()
	
	game_over_triggered.emit()

## Réinitialise le jeu pour une nouvelle partie
func reset_game() -> void:
	current_speed = initial_speed
	current_score = 0.0
	current_run_coins = 0
	is_game_over = false
	score_multiplier = 1.0
	
	# Arrêter le timer du multiplicateur
	if _multiplier_timer and _multiplier_timer.is_inside_tree():
		_multiplier_timer.stop()
	
	coins_updated.emit(current_run_coins)
	score_updated.emit(0)
	multiplier_updated.emit(1.0)

## Ramasse une pièce
func collect_coin() -> void:
	if not is_game_over:
		current_run_coins += 1
		coins_updated.emit(current_run_coins)

## Sauvegarde des données
func save_data() -> void:
	var config := ConfigFile.new()
	config.set_value("Leaderboard", "high_score", high_score)
	config.set_value("Economy", "total_coins", total_coins)
	
	var err := config.save(SAVE_PATH)
	if err != OK:
		push_error("Impossible de sauvegarder les données du jeu ! Erreur: ", err)

## Charge les données sauvegardées
func load_data() -> void:
	var config := ConfigFile.new()
	var err := config.load(SAVE_PATH)
	
	if err == OK:
		high_score = config.get_value("Leaderboard", "high_score", 0)
		total_coins = config.get_value("Economy", "total_coins", 0)
	else:
		# Données par défaut en cas d'erreur
		high_score = 0
		total_coins = 0
		push_warning("Aucune sauvegarde trouvée, données initialisées à 0")

## Vérifie et met à jour le high score
func check_new_highscore() -> void:
	var final_score := int(current_score)
	if final_score > high_score:
		high_score = final_score

# === PRIVATE METHODS ===

## Callback quand le multiplicateur expire
func _on_multiplier_timeout() -> void:
	score_multiplier = 1.0
	multiplier_updated.emit(score_multiplier)

## Callback quand l'aimant expire
func _on_magnet_timeout() -> void:
	is_magnet_active = false

## Nettoyage
func _exit_tree() -> void:
	# Nettoyer les timers
	if _multiplier_timer:
		_multiplier_timer.timeout.disconnect(_on_multiplier_timeout)
		_multiplier_timer.queue_free()
