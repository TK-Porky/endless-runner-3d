extends Area3D
class_name Obstacle

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		body.hit_obstacle()
		if body.has_shield:
			queue_free()
