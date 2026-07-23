extends PowerUp
class_name ScoreMultiplierPowerUp

@export var multiplier: float = 2.0

func activate_powerup(_player: Player) -> void:
	if GameManager.has_method("activate_score_multiplier"):
		GameManager.activate_score_multiplier(multiplier, duration)
