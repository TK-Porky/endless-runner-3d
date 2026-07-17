extends CanvasLayer
class_name MainMenu

@onready var coin_label: Label = $Control/EconomyElements/CoinLabel
@onready var high_score_label: Label =  $Control/MenuElements/HighScoreLabel
@onready var play_button: Button = $Control/MenuElements/PlayButton
@onready var quit_button: Button = $Control/MenuElements/QuitButton

const GAME_SCENE_PATH = "res://scenes/core/Main.tscn"

func _ready() -> void:
	high_score_label.text = "HighScore : " + str(GameManager.high_score)
	coin_label.text = str(GameManager.total_coins) + " Coins"
	
	play_button.pressed.connect(_on_play_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Confirm"):
		_on_play_pressed()
	if Input.is_action_just_pressed("Cancel"):
		_on_quit_pressed()

func _on_play_pressed() -> void:
	GameManager.reset_game()
	get_tree().change_scene_to_file(GAME_SCENE_PATH)

func _on_quit_pressed() -> void:
	get_tree().quit()
