extends CanvasLayer

@onready var live_score_label: Label = $LiveScoreLabel
@onready var high_score_label: Label = $HighScoreLabel

func _ready() -> void:
	GameManager.score_updated.connect(_on_score_updated)

func _on_score_updated(new_score: int) -> void:
	live_score_label.text = "Score : " + str(new_score)
	#high_score_label.text = "HighScore : " + str(GameManager.high_score)
