extends CanvasLayer

@onready var live_score_label: Label = $LiveScoreLabel
@onready var high_score_label: Label = $HighScoreLabel
@onready var live_coins_label: Label = $LiveCoinsLabel

func _ready() -> void:
	GameManager.score_updated.connect(_on_score_updated)
	GameManager.coins_updated.connect(_on_coin_collected)

func _on_coin_collected(coin_collected: int = 0) -> void:
	live_coins_label.text = str(coin_collected) + " Coins"

func _on_score_updated(new_score: int) -> void:
	live_score_label.text = "Score : " + str(new_score)
	#high_score_label.text = "HighScore : " + str(GameManager.high_score)
