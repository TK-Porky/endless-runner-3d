extends CanvasLayer

@onready var control_node: Control = $Control
@onready var restart_button: Button = $Control/RestartBtn
@onready var quit_button: Button = $Control/QuitBtn
@onready var score_label: Label = $Control/ScoreLabel

const MAIN_MENU_SCENE_PATH = "res://scenes/ui/MainMenu.tscn"

func _ready() -> void:
	control_node.visible = false
	
	GameManager.game_over_triggered.connect(show_game_over)
	
	restart_button.pressed.connect(_on_restart_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("Confirm") and GameManager.is_game_over:
		_on_restart_pressed()
	
	if Input.is_action_just_pressed("Cancel"):
		_on_quit_pressed()

func show_game_over() -> void:
	score_label.text = "Score : " + str(int(GameManager.current_score)) + "\n" + "Best Score : " + str(GameManager.high_score)
	control_node.visible = true

func _on_quit_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)

func _on_restart_pressed() -> void:
	GameManager.reset_game()
	get_tree().reload_current_scene()
