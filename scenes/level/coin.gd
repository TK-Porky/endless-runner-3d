extends Area3D

@export var rotation_speed: float = 3.0 

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	rotate_y(rotation_speed * delta)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		GameManager.add_score(100)
		# TODO : Jouer le son de collecte (Carte 13)
		
		queue_free()
