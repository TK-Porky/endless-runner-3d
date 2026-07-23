extends Control
class_name PowerUpIndicator

## ============================================================
## POWER-UP INDICATOR
## Affiche la progression d'un power-up actif avec une barre de temps
## ============================================================

# === SIGNALS ===

## Émis quand le power-up expire
signal powerup_expired(powerup_type: String)

# === VARIABLES ===

var powerup_type: String = ""

# === NODES ===

## Barre de progression représentant le temps restant
@onready var progress_bar: ProgressBar = $PowerUpTimeBar

## Label affichant le nom du power-up
@onready var label: Label = $PowerUpTimeBar/Label

# === VARIABLES ===

## Durée totale du power-up (en secondes)
var total_duration: float = 0.0

## Temps restant (en secondes)
var time_left: float = 0.0

## État actif du power-up (false = en cours de suppression)
var is_active: bool = false

## Animation d'entrée (optionnel)
var _has_played_entry_animation: bool = false

# === EXPORTS ===

## Couleur de la barre de progression (écrase le style par défaut)
@export var bar_color: Color = Color("99ff00")

## Seuil de warning (en secondes)
@export var warning_threshold: float = 2.0

## Vitesse de clignotement
@export var blink_speed: float = 5.0

# === INITIALIZATION ===

## Configure l'indicateur avec les paramètres du power-up
func setup(duration: float, powerup_label: String) -> void:
	powerup_type = powerup_label.to_lower()
	total_duration = duration
	time_left = duration
	label.text = powerup_label
	
	# Configurer la barre de progression
	progress_bar.max_value = 1.0
	progress_bar.value = 1.0
	
	# Appliquer la couleur de la barre
	_update_bar_color(bar_color)
	
	# Activer et afficher
	is_active = true
	visible = true
	
	# Jouer l'animation d'entrée
	_play_entry_animation()

# === GAME LOOP ===

## Met à jour la barre de progression et gère l'expiration
func _process(delta: float) -> void:
	if not is_active:
		return
	
	# Décrémenter le temps restant
	time_left -= delta
	
	# Calculer la progression (0 = vide, 1 = plein)
	var progress = max(time_left / total_duration, 0.0)
	progress_bar.value = progress
	
	# Gérer l'état de warning (temps restant faible)
	_handle_warning_state(progress)
	
	# Vérifier l'expiration
	if time_left <= 0.0:
		_expire()

# === WARNING STATE ===

## Gère les effets visuels quand le power-up est sur le point d'expirer
func _handle_warning_state(_progress: float) -> void:
	if time_left <= 0.0:
		return
	
	# Mode warning : clignotement et changement de couleur
	if time_left <= warning_threshold:
		_warning_mode()
	else:
		_normal_mode()

## Active le mode warning (clignotement + couleur rouge)
func _warning_mode() -> void:
	# Clignotement rapide
	var blink := sin(Time.get_ticks_msec() / 1000.0 * blink_speed)
	modulate.a = 0.5 + 0.5 * abs(blink)

## Désactive le mode warning (retour à la normale)
func _normal_mode() -> void:
	modulate.a = 1.0
	_update_bar_color(bar_color)

## Met à jour la couleur de la barre de progression
func _update_bar_color(color: Color) -> void:
	if not progress_bar:
		return
	
	# Changer la couleur de la barre via un stylebox modulé
	var stylebox := progress_bar.get_theme_stylebox("fill")
	if stylebox:
		stylebox.bg_color = color

# === ANIMATIONS ===

## Joue l'animation d'entrée (apparition)
func _play_entry_animation() -> void:
	if _has_played_entry_animation:
		return
	
	_has_played_entry_animation = true
	
	# Animation d'apparition
	scale = Vector2(0.5, 0.5)
	modulate.a = 0.0
	
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ONE, 0.3).set_ease(Tween.EASE_OUT_IN)
	tween.tween_property(self, "modulate:a", 1.0, 0.2)

## Joue l'animation de sortie (disparition)
func _play_exit_animation() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(0.5, 0.5), 0.2).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	await tween.finished

## Joue une animation quand le power-up est réinitialisé
func _play_refresh_animation() -> void:
	# Animation de "pop" pour indiquer la réinitialisation
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.1).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.7, 0.1)
	tween.tween_property(self, "scale", Vector2.ONE, 0.15).set_delay(0.1).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "modulate:a", 1.0, 0.15).set_delay(0.1)

# === EXPIRATION ===

## Gère l'expiration du power-up
func _expire() -> void:
	if not is_active:
		return
	
	is_active = false
	
	powerup_expired.emit(powerup_type)
	
	# Jouer l'animation de sortie
	await _play_exit_animation()
	
	# Supprimer l'indicateur
	queue_free()

# === PUBLIC METHODS ===

## Réinitialise la durée du power-up (si un autre est collecté)
func reset_duration(new_duration: float) -> void:
	if not is_active:
		return
	
	# Réinitialiser complètement le temps
	total_duration = new_duration
	time_left = new_duration
	
	# Mettre à jour la barre
	progress_bar.max_value = 1.0
	progress_bar.value = 1.0
	
	# Quitter le mode warning si actif
	modulate.a = 1.0
	
	# Effet visuel de réinitialisation
	_play_refresh_animation()

## Force la suppression de l'indicateur
func force_dismiss() -> void:
	if not is_active:
		return
	
	is_active = false
	queue_free()

# === CLEANUP ===

## Déconnecte les signaux et nettoie
func _exit_tree() -> void:
	# Annuler les tweens
	if create_tween():
		create_tween().kill()
