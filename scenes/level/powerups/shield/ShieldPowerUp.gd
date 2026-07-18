extends PowerUp
class_name ShieldPowerUp

func activate_powerup(player: Player) -> void:
	if player.has_method("activate_shield"):
		player.activate_shield()
