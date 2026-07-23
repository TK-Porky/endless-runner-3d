extends CanvasLayer
class_name GameOverScreen

## ============================================================
## GAME OVER SCREEN
## Écran affiché à la fin de la partie avec score et options
## ============================================================

# === SIGNALS ===

## Émis quand le joueur demande à quitter le jeu
signal quit_triggered

## Émis quand le joueur demande à recommencer
signal restart_triggered

# === NODES ===

## Nœud principal contenant tous les éléments UI
@onready var control_node: Control = $Control

## Bouton pour recommencer la partie
@onready var restart_button: Button = %RestartBtn

## Bouton pour quitter le jeu
@onready var quit_button: Button = %QuitBtn

## Label affichant le score et le high score
@onready var score_label: Label = $Control/ScoreLabel

# === VARIABLES ===

## Empêche les doubles appuis sur "Quitter"
var _is_quitting: bool = false

## Empêche les doubles appuis sur "Recommencer"
var _is_restarting: bool = false

# === INITIALIZATION ===

func _ready() -> void:
	# Cacher l'écran au démarrage
	_hide_screen()
	
	# Connecter les signaux du GameManager
	_connect_game_signals()
	
	# Connecter les boutons
	_connect_buttons()

## Connecte les signaux du GameManager
func _connect_game_signals() -> void:
	if not GameManager:
		push_warning("GameOverScreen: GameManager introuvable !")
		return
	
	GameManager.game_over_triggered.connect(_on_game_over)

## Connecte les signaux des boutons
func _connect_buttons() -> void:
	if restart_button:
		restart_button.pressed.connect(_on_restart_pressed)
	else:
		push_warning("GameOverScreen: RestartBtn introuvable !")
	
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)
	else:
		push_warning("GameOverScreen: QuitBtn introuvable !")

# === INPUT ===

## Gère les raccourcis clavier
func _input(event: InputEvent) -> void:
	# Vérifier que l'écran est visible
	if not visible:
		return
	
	# Raccourci "Entrée/Espace" pour recommencer
	if event.is_action_pressed("Confirm") and GameManager.is_game_over:
		_on_restart_pressed()
	
	# Raccourci "Échap" pour quitter
	if event.is_action_pressed("Cancel"):
		_on_quit_pressed()

# === PUBLIC METHODS ===

## Affiche l'écran de game over avec les scores
func show_game_over() -> void:
	_update_score_display()
	_show_screen()

## Cache l'écran de game over
func hide_game_over() -> void:
	_hide_screen()

## Met à jour les scores affichés (peut être appelé depuis l'extérieur)
func update_scores() -> void:
	_update_score_display()

# === PRIVATE METHODS ===

## Met à jour l'affichage des scores
func _update_score_display() -> void:
	if not score_label:
		return
	
	var current_score := int(GameManager.current_score)
	var high_score := GameManager.high_score
	
	# Formatage du texte avec les scores
	score_label.text = "Score : " + str(current_score) + "\n" + "Best Score : " + str(high_score)

## Affiche l'écran avec animation (optionnel)
func _show_screen() -> void:
	visible = true
	
	# Effet simple : apparition progressive
	control_node.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(control_node, "modulate:a", 1.0, 0.3)

## Cache l'écran
func _hide_screen() -> void:
	visible = false

# === SIGNAL HANDLERS ===

## Appelé quand le jeu se termine
func _on_game_over() -> void:
	show_game_over()

## Appelé quand le bouton "Recommencer" est pressé
func _on_restart_pressed() -> void:
	if _is_restarting:
		return
	
	_is_restarting = true
	hide_game_over()
	
	# Petit délai pour éviter les doubles appuis
	await get_tree().create_timer(0.1).timeout
	
	restart_triggered.emit()
	
	# Réinitialiser l'état après l'émission
	_is_restarting = false

## Appelé quand le bouton "Quitter" est pressé
func _on_quit_pressed() -> void:
	if _is_quitting:
		return
	
	_is_quitting = true
	hide_game_over()
	
	# Petit délai pour éviter les doubles appuis
	await get_tree().create_timer(0.1).timeout
	
	quit_triggered.emit()
	
	# Réinitialiser l'état après l'émission
	_is_quitting = false

# === RESET ===

## Réinitialise l'état de l'écran (pour une nouvelle partie)
func reset_screen() -> void:
	_is_quitting = false
	_is_restarting = false
	visible = false
	control_node.visible = false

# === CLEANUP ===

## Déconnecte les signaux pour éviter les fuites mémoire
func _exit_tree() -> void:
	# Déconnecter les signaux du GameManager
	if GameManager and GameManager.game_over_triggered.is_connected(_on_game_over):
		GameManager.game_over_triggered.disconnect(_on_game_over)
	
	# Déconnecter les signaux des boutons
	if restart_button and restart_button.pressed.is_connected(_on_restart_pressed):
		restart_button.pressed.disconnect(_on_restart_pressed)
	
	if quit_button and quit_button.pressed.is_connected(_on_quit_pressed):
		quit_button.pressed.disconnect(_on_quit_pressed)
