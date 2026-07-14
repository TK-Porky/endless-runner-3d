extends Node3D

const COIN_SCENE = preload("res://scenes/level/Coin.tscn")
const LOW_OBSTACLE_SCENE = preload("res://scenes/level/LowObstacle.tscn")
const HIGH_OBSTACLE_SCENE = preload("res://scenes/level/HighObstacle.tscn")

var player: Player = null

func _ready() -> void:
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		player = players[0]
	
	spawn_objects()

func spawn_objects() -> void:
	var spawn_points_container = get_node_or_null("SpawnPoints")
	if not spawn_points_container:
		return

	for marker in spawn_points_container.get_children():
		if marker is Marker3D:
			var r = randi() % 10
			
			if r < 3:
				spawn_item(COIN_SCENE, marker.position)
			elif r < 5:
				spawn_item(LOW_OBSTACLE_SCENE, marker.position)
			elif r < 7:
				spawn_item(HIGH_OBSTACLE_SCENE, marker.position)

func spawn_item(packed_scene: PackedScene, local_position: Vector3) -> void:
	var item = packed_scene.instantiate() as Node3D
	add_child(item)
	item.position = local_position

func _process(_delta: float) -> void:
	if player and player.global_position.z < global_position.z - 65.0:
		queue_free()
