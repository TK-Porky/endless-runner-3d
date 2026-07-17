extends Area3D

@export var rotation_speed: float = 3.0 
@onready var pickup_sound: AudioStreamPlayer = $PickupSound

var _collected: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if not _collected:
		rotate_y(rotation_speed * delta)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player") and not _collected:
		_collected = true
		GameManager.collect_coin()
		
		visible = false
		set_deferred("monitoring", false)
		pickup_sound.play()
		await pickup_sound.finished
		
		queue_free()
