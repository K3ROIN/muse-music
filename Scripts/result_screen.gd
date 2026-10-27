extends Control

# ==============================================================================
# Result Screen (Scenes/result_screen.tscn)
# รองรับทั้งกรณีเล่นจบเพลง ("STAGE CLEAR!") และกรณี Stamina หมด ("STAGE FAILED!")
# ==============================================================================

@onready var panel: Panel = $CenterContainer/Panel
@onready var title_label: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/TitleLabel
@onready var rank_label: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/RankLabel
@onready var score_label: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/StatsVBox/ScoreLabel
@onready var accuracy_label: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/StatsVBox/AccuracyLabel
@onready var max_combo_label: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/StatsVBox/MaxComboLabel
@onready var perfect_label: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/StatsVBox/PerfectLabel
@onready var miss_label: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/StatsVBox/MissLabel

@onready var retry_button = find_child("RetryButton", true, false)
@onready var song_select_button = find_child("SongSelectButton", true, false)
@onready var main_menu_button = find_child("MainMenuButton", true, false)

@export var is_overlay_in_world: bool = true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	if is_overlay_in_world and get_tree().current_scene != self:
		hide()
		if typeof(GameManager) != TYPE_NIL:
			GameManager.song_finished_for_result.connect(show_result)
	else:
		show_result()


func show_result() -> void:
	show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	var final_score: int = GameManager.score
	var final_acc: float = GameManager.get_accuracy_percent()
	var final_combo: int = GameManager.max_combo
	var final_perfect: int = GameManager.perfect_count
	var final_miss: int = GameManager.miss_count
	var rank_text: String = GameManager.get_rank()

	# แสดงหัวข้อตามสถานะว่าผ่านด่านหรือ Stamina หมด
	if title_label:
		if GameManager.is_game_over:
			title_label.text = "STAGE FAILED!"
			title_label.modulate = Color(1.0, 0.35, 0.35)
		else:
			title_label.text = "STAGE CLEAR!"
			title_label.modulate = Color(1.0, 1.0, 1.0)

	rank_label.text = "RANK: " + rank_text
	_apply_rank_color(rank_text)

	accuracy_label.text = "ACCURACY: %.2f%%" % final_acc
	max_combo_label.text = "MAX COMBO: %d" % final_combo
	perfect_label.text = "PERFECT: %d" % final_perfect
	miss_label.text = "MISS: %d" % final_miss

	if panel:
		panel.pivot_offset = panel.size / 2.0
		panel.scale = Vector2(0.8, 0.8)
		var pop_tween: Tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		pop_tween.tween_property(panel, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	var score_tween: Tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	score_tween.tween_method(
		func(val: int): score_label.text = "SCORE: %d" % val,
		0,
		final_score,
		0.8
	).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)


func _apply_rank_color(rank_text: String) -> void:
	if not rank_label:
		return
	match rank_text:
		"S+", "S":
			rank_label.modulate = Color(1.0, 0.84, 0.2)
		"A":
			rank_label.modulate = Color(0.35, 0.9, 0.55)
		"B":
			rank_label.modulate = Color(0.4, 0.75, 1.0)
		"C":
			rank_label.modulate = Color(1.0, 0.65, 0.3)
		_:
			rank_label.modulate = Color(0.95, 0.4, 0.4)


func _on_retry_button_pressed() -> void:
	get_tree().paused = false
	GameManager.reset_stats()
	if is_overlay_in_world and get_tree().current_scene != self:
		get_tree().reload_current_scene()
	else:
		get_tree().change_scene_to_file("res://Scenes/world.tscn")


func _on_song_select_button_pressed() -> void:
	get_tree().paused = false
	GameManager.reset_stats()
	get_tree().change_scene_to_file("res://Scenes/song_selection.tscn")


func _on_main_menu_button_pressed() -> void:
	get_tree().paused = false
	GameManager.reset_stats()
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
