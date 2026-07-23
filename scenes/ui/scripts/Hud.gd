extends CanvasLayer
class_name HUD

## ============================================================
## HUD (Head-Up Display)
## Affiche les informations de jeu en temps réel :
## - Score actuel
## - High score
## - Multiplicateur de score
## - Pièces collectées
## - Indicateurs de power-ups
## ============================================================

# === NODES ===

## Label affichant le multiplicateur de score (ex: "X 2")
@onready var multiplier_score_label: Label = %MultiplierScoreLabel

## Label affichant le score en cours (avec padding de zéros)
@onready var live_score_label: Label = %LiveScoreLabel

## Label affichant le nombre de pièces collectées
@onready var live_coins_label: Label = %LiveCoinsLabel

## Label affichant le meilleur score
@onready var high_score_label: Label = %HighScoreLabel

## Conteneur pour les indicateurs de power-ups actifs
@onready var power_up_container: Container = $PowerUpContainer

## Animation player pour les effets visuels
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# === EXPORTS ===

## Scène de l'indicateur de power-up (à instancier dynamiquement)
@export var indicator_scene: PackedScene

## Format d'affichage du score (avec padding)
@export var score_padding: int = 9

# === VARIABLES ===

## Cache du high score pour éviter les appels répétés
var _cached_high_score: int = 0

## Liste des power-ups actifs pour éviter des instanciations répétées
var _active_powerups: Dictionary = {} 

# === INITIALIZATION ===

func _ready() -> void:
	# Initialiser l'affichage
	_reset_display()
	
	# Connecter les signaux du GameManager
	_connect_signals()
	
	# Vérifier que les nœuds essentiels existent
	_validate_nodes()

## Connecte tous les signaux du GameManager
func _connect_signals() -> void:
	if not GameManager:
		push_warning("HUD: GameManager introuvable !")
		return
	
	GameManager.score_updated.connect(_on_score_updated)
	GameManager.coins_updated.connect(_on_coins_updated)
	GameManager.multiplier_updated.connect(_on_multiplier_updated)
	GameManager.game_over_triggered.connect(_on_game_over)
	GameManager.power_up_activated.connect(_on_power_up_activated)

## Vérifie que tous les nœuds essentiels sont présents
func _validate_nodes() -> void:
	if not multiplier_score_label:
		push_warning("HUD: MultiplierScoreLabel introuvable !")
	if not live_score_label:
		push_warning("HUD: LiveScoreLabel introuvable !")
	if not live_coins_label:
		push_warning("HUD: LiveCoinsLabel introuvable !")
	if not high_score_label:
		push_warning("HUD: HighScoreLabel introuvable !")
	if not power_up_container:
		push_warning("HUD: PowerUpContainer introuvable !")

## Réinitialise l'affichage du HUD
func _reset_display() -> void:
	live_score_label.text = "0".pad_zeros(score_padding)
	live_coins_label.text = "0 Coins"
	multiplier_score_label.text = "X 1"
	high_score_label.text = "HighScore : 0"
	_cached_high_score = 0
	
	# Vider les indicateurs de power-ups
	_clear_power_ups()

# === PUBLIC METHODS ===

## Met à jour manuellement l'affichage (peut être appelé depuis l'extérieur)
func refresh_display() -> void:
	if GameManager:
		_on_score_updated(int(GameManager.current_score))
		_on_coins_updated(GameManager.current_run_coins)
		_on_multiplier_updated(int(GameManager.score_multiplier))
		_update_high_score(GameManager.high_score)

## Affiche un message temporaire (ex: "Perfect!", "Combo x5!")
func show_floating_text(text: String, color: Color = Color.WHITE) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", 24)
	label.position = Vector2(400, 300)  # Centre de l'écran
	
	add_child(label)
	
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", 200, 1.0).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 1.0).set_delay(0.5)
	tween.tween_callback(label.queue_free).set_delay(1.5)

# === PRIVATE METHODS ===

## Efface tous les indicateurs de power-ups
func _clear_power_ups() -> void:
	if not power_up_container:
		return
	
	for child in power_up_container.get_children():
		child.queue_free()

## Met à jour le high score avec animation si nouveau record
func _update_high_score(new_high_score: int) -> void:
	if new_high_score > _cached_high_score and _cached_high_score > 0:
		# Nouveau record ! Animation spéciale
		_play_high_score_animation()
	
	_cached_high_score = new_high_score
	high_score_label.text = "HighScore : " + str(new_high_score)

## Joue une animation pour un nouveau record
func _play_high_score_animation() -> void:
	if not animation_player:
		return
	
	if animation_player.has_animation("HighScore_Up"):
		animation_player.play("HighScore_Up")
	else:
		# Animation simple par défaut
		var tween := create_tween()
		tween.tween_property(high_score_label, "scale", Vector2(1.2, 1.2), 0.2)
		tween.tween_property(high_score_label, "scale", Vector2(1.0, 1.0), 0.2)

# === SIGNAL HANDLERS ===

## Met à jour le score en temps réel
func _on_score_updated(new_score: int) -> void:
	live_score_label.text = str(new_score).pad_zeros(score_padding)

## Met à jour le nombre de pièces
func _on_coins_updated(coin_count: int) -> void:
	live_coins_label.text = str(coin_count) + " Coins"

## Met à jour l'affichage du multiplicateur avec animation
func _on_multiplier_updated(current_multiplier: int = 1) -> void:
	multiplier_score_label.text = "X " + str(current_multiplier)
	
	# Jouer l'animation si le multiplicateur change
	if animation_player and animation_player.has_animation("Multiplier_up"):
		animation_player.play("Multiplier_up")

## Cache le HUD quand le jeu est terminé
func _on_game_over() -> void:
	# Animation de disparition (optionnel)
	if animation_player and animation_player.has_animation("HUD_Hide"):
		animation_player.play("HUD_Hide")
		await animation_player.animation_finished
	
	hide()

## Ajoute un indicateur de power-up actif
func _on_power_up_activated(duration: float, powerup_label: String) -> void:
	if not indicator_scene:
		push_warning("HUD: indicator_scene non défini !")
		return
	
	if not power_up_container:
		return
		
	var powerup_type := powerup_label.to_lower()
	
	if _active_powerups.has(powerup_type):
		var existing_indicator : PowerUpIndicator = _active_powerups[powerup_type]
		
		# Si l'indicateur existe toujours et est actif
		if is_instance_valid(existing_indicator) and existing_indicator.is_active:
			# Prolonger la durée au lieu de créer un nouveau
			existing_indicator.reset_duration(duration)
			return
		else:
			# Nettoyer la référence si l'indicateur a été supprimé
			_active_powerups.erase(powerup_type)
	
	var new_indicator := indicator_scene.instantiate() as PowerUpIndicator
	if not new_indicator:
		push_error("HUD: Impossible d'instancier l'indicateur de power-up !")
		return
	
	# Ajouter au conteneur
	power_up_container.add_child(new_indicator)
	new_indicator.setup(duration, powerup_label)
	
	# Stocker la référence avec son type
	_active_powerups[powerup_type] = new_indicator
	
	# Connecter le signal de fin pour nettoyer la référence
	new_indicator.powerup_expired.connect(_on_powerup_expired.bind(powerup_type))

## Vérifie si un power-up est actif
func is_powerup_active(powerup_type: String) -> bool:
	return _active_powerups.has(powerup_type)

## Récupère l'indicateur d'un power-up actif
func get_powerup_indicator(powerup_type: String) -> PowerUpIndicator:
	return _active_powerups.get(powerup_type, null)

# === RESET ===

## Réinitialise complètement le HUD pour une nouvelle partie
func reset_hud() -> void:
	_reset_display()
	show()
	
	# Reconnecter les signaux si nécessaire
	if GameManager and not GameManager.score_updated.is_connected(_on_score_updated):
		_connect_signals()

# === CLEANUP ===

## Nettoie la référence quand un power-up expire
func _on_powerup_expired(powerup_type: String) -> void:
	if _active_powerups.has(powerup_type):
		_active_powerups.erase(powerup_type)

## Nettoie tous les power-ups (au game over ou reset)
func clear_all_powerups() -> void:
	for indicator in _active_powerups.values():
		if is_instance_valid(indicator):
			indicator.force_dismiss()
	_active_powerups.clear()

## Déconnecte les signaux pour éviter les fuites mémoire
func _exit_tree() -> void:
	if not GameManager:
		return
	
	if GameManager.score_updated.is_connected(_on_score_updated):
		GameManager.score_updated.disconnect(_on_score_updated)
	
	if GameManager.coins_updated.is_connected(_on_coins_updated):
		GameManager.coins_updated.disconnect(_on_coins_updated)
	
	if GameManager.multiplier_updated.is_connected(_on_multiplier_updated):
		GameManager.multiplier_updated.disconnect(_on_multiplier_updated)
	
	if GameManager.game_over_triggered.is_connected(_on_game_over):
		GameManager.game_over_triggered.disconnect(_on_game_over)
	
	if GameManager.power_up_activated.is_connected(_on_power_up_activated):
		GameManager.power_up_activated.disconnect(_on_power_up_activated)
