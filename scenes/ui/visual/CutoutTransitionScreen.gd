extends Control
class_name TransitionScreen

## ============================================================
## TRANSITION SCREEN
## Écran de transition avec animations de fondu (fade)
## Utilisé pour les changements de scène ou les game overs
## ============================================================

# === SIGNALS ===

## Émis quand l'animation de transition commence
signal transition_anim_started

## Émis quand l'animation de transition est terminée
signal transition_anim_finished

# === NODES ===

## Référence au nœud AnimationPlayer
@onready var animation_player: AnimationPlayer = %AnimationPlayer

# === PUBLIC METHODS ===

## Démarre une transition : fondu depuis le noir vers la scène
## Utilisé à l'arrivée sur une nouvelle scène
func start_from_transition() -> void:
	animation_player.play("FadeFromBlack")
	transition_anim_started.emit()

## Démarre une transition : fondu vers le noir depuis la scène
## Utilisé avant de quitter une scène
func start_to_transition() -> void:
	animation_player.play("FadeToBlack")
	transition_anim_started.emit()

## Émet le signal de fin de transition (à appeler depuis l'animation)
## Utiliser comme appel de méthode dans AnimationPlayer
func emit_transition_finished() -> void:
	transition_anim_finished.emit()

# === PRIVATE METHODS ===

## Vérifie que l'animation existe avant de jouer
func _play_animation(anim_name: String) -> bool:
	if not animation_player:
		push_error("TransitionScreen: AnimationPlayer introuvable !")
		return false
	
	if not animation_player.has_animation(anim_name):
		push_error("TransitionScreen: Animation '%s' introuvable !" % anim_name)
		return false
	
	return true

# === OVERRIDES ===

## Cache le curseur et initialise l'écran
func _ready() -> void:
	# Cacher le curseur pendant les transitions (optionnel)
	# Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	
	# Vérifier que l'animation existe
	if not _play_animation("FadeFromBlack"):
		push_warning("TransitionScreen: Animations de transition manquantes !")
		
	# Optionnel: démarrer en fondu depuis le noir
	# await get_tree().process_frame
	# start_from_transition()

# === HELPER METHODS ===

## Transition complète pour un changement de scène
## @param next_scene: Chemin vers la scène à charger
func transition_to_scene(_next_scene: String) -> void:
	# 1. Fondu vers le noir
	start_to_transition()
	
	# 2. Attendre la fin de l'animation
	await transition_anim_finished
	
	# 3. Charger la nouvelle scène
	# get_tree().change_scene_to_file(next_scene)
	
	# 4. Fondu depuis le noir
	start_from_transition()

## Transition rapide avec callback
## @param callback: Fonction à exécuter pendant le fondu noir
func transition_with_callback(callback: Callable) -> void:
	start_to_transition()
	await transition_anim_finished
	callback.call()
	start_from_transition()
