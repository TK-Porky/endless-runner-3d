extends Node

signal game_over_triggered
signal score_updated(new_score: int)
signal coins_updated(total_coins: int)
signal total_coins_updated(total_coins: int)

var initial_speed := 15.0
var max_speed := 60.0
var acceleration_rate := 0.2

var current_speed := 0.0
var is_game_over := false

const SAVE_PATH = "user://save_data.cfg"

var current_score: float = 0.0
var high_score: int = 0

var current_run_coins: int = 0
var total_coins: int = 0

func _ready() -> void:
	load_data()
	reset_game()

func _process(delta: float) -> void:
	if not is_game_over:
		
		if current_speed < max_speed:
			current_speed += acceleration_rate * delta
			current_speed = clamp(current_speed, initial_speed, max_speed)
		
		current_score += current_speed * delta
		score_updated.emit(int(current_score))

func add_score(amount: int) -> void:
	if not is_game_over:
		current_score += amount
		score_updated.emit(int(current_score))

func trigger_game_over() -> void:
	if is_game_over: return
	
	is_game_over = true
	current_speed = 0.0
	
	total_coins += current_run_coins
	total_coins_updated.emit(total_coins)
	
	check_new_highscore()
	save_data()
	
	game_over_triggered.emit()

func reset_game() -> void:
	current_speed = initial_speed
	current_score = 0.0
	current_run_coins = 0
	is_game_over = false
	coins_updated.emit(current_run_coins)

func collect_coin() -> void:
	if not is_game_over:
		current_run_coins += 1
		coins_updated.emit(current_run_coins)

func check_new_highscore() -> void:
	var final_score = int(current_score)
	if final_score > high_score:
		high_score = final_score

func save_data() -> void:
	var config = ConfigFile.new()
	config.set_value("Leaderboard", "high_score", high_score)
	config.set_value("Economy", "total_coins", total_coins)
	
	var err = config.save(SAVE_PATH)
	if err != OK:
		push_error("Impossible de sauvegarder les données du jeu !")

func load_data() -> void:
	var config = ConfigFile.new()
	var err = config.load(SAVE_PATH)
	
	if err == OK:
		high_score = config.get_value("Leaderboard", "high_score", 0)
		total_coins = config.get_value("Economy", "total_coins", 0)
	else:
		high_score = 0
		total_coins = 0
