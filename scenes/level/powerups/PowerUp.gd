extends Area3D
class_name PowerUp

@export var duration: float = 10.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	rotate_y(deg_to_rad(90.0) * delta)

func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		activate_powerup(body)
		queue_free()

func activate_powerup(player: Player) -> void:
	pass
