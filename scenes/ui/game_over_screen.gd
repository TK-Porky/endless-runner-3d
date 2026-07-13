extends CanvasLayer

@onready var control_node: Control = $Control
@onready var restart_button: Button = $Control/RestartBtn
@onready var quit_button: Button = $Control/QuitBtn

func _ready() -> void:
	control_node.visible = false
	
	GameManager.game_over_triggered.connect(show_game_over)
	
	restart_button.pressed.connect(_on_restart_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func show_game_over() -> void:
	control_node.visible = true

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_restart_pressed() -> void:
	GameManager.reset_game()
	get_tree().reload_current_scene()
