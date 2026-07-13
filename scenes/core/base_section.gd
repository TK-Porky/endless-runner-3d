extends Node3D
class_name BaseSection

@onready var end_marker: Marker3D = $EndMarker

var player: Player = null

func _ready() -> void:
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		player = players[0]

func _process(_delta: float) -> void:
	if player:
		if player.global_position.z < global_position.z - 65.0:
			queue_free()
