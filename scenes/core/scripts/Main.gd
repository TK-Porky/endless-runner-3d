extends Node3D
class_name Main

## ============================================================
## MAIN
## Scène principale du jeu - Gère les transitions et le cycle de vie
## ============================================================

# === CONSTANTS ===

## Chemin vers la scène du menu principal
const MAIN_MENU_SCENE_PATH: String = "res://scenes/ui/MainMenu.tscn"

# === NODES ===

## Écran de transition avec effet de fondu
@onready var cutout_transition_screen: TransitionScreen = %CutoutTransitionScreen

## Écran de game over
@onready var game_over_screen: GameOverScreen = $GameOverScreen

# === VARIABLES ===

## Empêche les doubles transitions
var _is_transitioning: bool = false

# === INITIALIZATION ===

func _ready() -> void:
	# Connecter les signaux
	_connect_signals()
	
	# Démarrer avec une transition d'entrée
	_show_entry_transition()
	
	# Ajouter au groupe pour un accès facile
	add_to_group("Main")

## Connecte tous les signaux nécessaires
func _connect_signals() -> void:
	# Transition d'entrée
	if cutout_transition_screen:
		cutout_transition_screen.transition_anim_finished.connect(_on_transition_finished)
	else:
		push_warning("Main: CutoutTransitionScreen introuvable !")
	
	# Game Over Screen
	if game_over_screen:
		game_over_screen.quit_triggered.connect(_on_quit)
		game_over_screen.restart_triggered.connect(_on_restart)
	else:
		push_warning("Main: GameOverScreen introuvable !")

## Affiche la transition d'entrée
func _show_entry_transition() -> void:
	if not cutout_transition_screen:
		return
	
	cutout_transition_screen.start_from_transition()

# === INPUT ===

## Gère les raccourcis clavier globaux
func _input(event: InputEvent) -> void:
	# Quitter avec Échap (uniquement si pas en transition)
	if event.is_action_pressed("Cancel") and not _is_transitioning:
		# Si le game over est affiché, le GameOverScreen gère déjà le Cancel
		if game_over_screen and game_over_screen.visible:
			return
		
		# Sinon, quitter vers le menu
		_on_quit()

# === SIGNAL HANDLERS ===

## Appelé quand la transition d'entrée est terminée
func _on_transition_finished() -> void:
	if cutout_transition_screen:
		cutout_transition_screen.hide()

## Appelé quand le joueur demande à quitter
func _on_quit() -> void:
	if _is_transitioning:
		return
	
	_is_transitioning = true
	await _transition_to_scene(MAIN_MENU_SCENE_PATH)
	_is_transitioning = false

## Appelé quand le joueur demande à recommencer
func _on_restart() -> void:
	if _is_transitioning:
		return
	
	_is_transitioning = true
	
	# Transition vers le noir
	await _transition_out()
	
	# Réinitialiser le jeu
	GameManager.reset_game()
	
	# Recharger la scène
	get_tree().reload_current_scene()
	
	_is_transitioning = false

# === TRANSITION METHODS ===

## Effectue une transition vers une nouvelle scène
## @param scene_path: Chemin vers la scène de destination
func _transition_to_scene(scene_path: String) -> void:
	# Transition vers le noir
	await _transition_out()
	
	# Charger la nouvelle scène
	var error := get_tree().change_scene_to_file(scene_path)
	if error != OK:
		push_error("Main: Impossible de charger la scène : ", scene_path)

## Effectue la transition vers le noir
func _transition_out() -> void:
	if not cutout_transition_screen:
		return
	
	cutout_transition_screen.start_to_transition()
	await cutout_transition_screen.transition_anim_finished

## Effectue la transition depuis le noir
func _transition_in() -> void:
	if not cutout_transition_screen:
		return
	
	cutout_transition_screen.start_from_transition()
	await cutout_transition_screen.transition_anim_finished
	cutout_transition_screen.hide()

# === PUBLIC METHODS ===

## Transition vers le menu principal (peut être appelé depuis l'extérieur)
func go_to_main_menu() -> void:
	if _is_transitioning:
		return
	
	_is_transitioning = true
	await _transition_to_scene(MAIN_MENU_SCENE_PATH)
	_is_transitioning = false

## Redémarre le niveau (peut être appelé depuis l'extérieur)
func restart_level() -> void:
	if _is_transitioning:
		return
	
	_is_transitioning = true
	await _transition_out()
	GameManager.reset_game()
	get_tree().reload_current_scene()
	_is_transitioning = false

# === CLEANUP ===

## Déconnecte les signaux pour éviter les fuites mémoire
func _exit_tree() -> void:
	if cutout_transition_screen:
		if cutout_transition_screen.transition_anim_finished.is_connected(_on_transition_finished):
			cutout_transition_screen.transition_anim_finished.disconnect(_on_transition_finished)
	
	if game_over_screen:
		if game_over_screen.quit_triggered.is_connected(_on_quit):
			game_over_screen.quit_triggered.disconnect(_on_quit)
		if game_over_screen.restart_triggered.is_connected(_on_restart):
			game_over_screen.restart_triggered.disconnect(_on_restart)
