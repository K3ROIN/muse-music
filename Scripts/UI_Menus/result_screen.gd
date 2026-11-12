extends Control

@export_group("Behavior & Button Colors (ปรับใน Inspector ได้)")
@export var is_overlay_in_world: bool = true
@export var button_normal_color: Color = Color(0.961, 0.937, 0.886, 1.0)
@export var button_text_color: Color = Color(0.086, 0.071, 0.141, 1.0)
@export var button_shadow_color: Color = Color(0.043, 0.031, 0.071, 1.0)
@export var hover_colors: Array[Color] = [
	Color(1.0, 0.81, 0.28, 1.0),  # 1. RETRY     -> เหลืองทอง
	Color(0.45, 1.0, 0.62, 1.0),  # 2. SONGS     -> เขียวมินต์
	Color(0.36, 0.90, 1.0, 1.0)   # 3. MAIN MENU -> ฟ้าไซเบอร์
]

@onready var panel: PanelContainer = find_child("Panel", true, false) as PanelContainer
@onready var title_label: Label = find_child("TitleLabel", true, false) as Label
@onready var song_name_label: Label = find_child("SongNameLabel", true, false) as Label
@onready var full_combo_badge: Label = find_child("FullComboBadge", true, false) as Label

@onready var rank_circle_panel: Panel = find_child("RankCirclePanel", true, false) as Panel
@onready var rank_label: Label = find_child("RankLabel", true, false) as Label
@onready var stars_label: Label = find_child("StarsLabel", true, false) as Label

@onready var score_label: Label = find_child("ScoreLabel", true, false) as Label
@onready var accuracy_label: Label = find_child("AccuracyLabel", true, false) as Label
@onready var accuracy_bar: ProgressBar = find_child("AccuracyBar", true, false) as ProgressBar
@onready var max_combo_label: Label = find_child("MaxComboLabel", true, false) as Label
@onready var perfect_label: Label = find_child("PerfectLabel", true, false) as Label
@onready var miss_label: Label = find_child("MissLabel", true, false) as Label

@onready var retry_button: Button = find_child("RetryButton", true, false) as Button
@onready var song_select_button: Button = find_child("SongSelectButton", true, false) as Button
@onready var main_menu_button: Button = find_child("MainMenuButton", true, false) as Button

var _action_buttons: Array[Button] = []
var _btn_styleboxes: Dictionary = {}
var _btn_hover_tweens: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = 95

	_setup_juice_kit_buttons()

	if is_overlay_in_world and get_tree().current_scene != self:
		hide()
		if typeof(GameManager) != TYPE_NIL:
			if not GameManager.song_finished_for_result.is_connected(show_result):
				GameManager.song_finished_for_result.connect(show_result)
	else:
		show_result()


func _setup_juice_kit_buttons() -> void:
	_action_buttons.clear()
	if retry_button != null:
		_action_buttons.append(retry_button)
		if not retry_button.pressed.is_connected(_on_retry_button_pressed):
			retry_button.pressed.connect(_on_retry_button_pressed)
	if song_select_button != null:
		_action_buttons.append(song_select_button)
		if not song_select_button.pressed.is_connected(_on_song_select_button_pressed):
			song_select_button.pressed.connect(_on_song_select_button_pressed)
	if main_menu_button != null:
		_action_buttons.append(main_menu_button)
		if not main_menu_button.pressed.is_connected(_on_main_menu_button_pressed):
			main_menu_button.pressed.connect(_on_main_menu_button_pressed)

	for i in range(_action_buttons.size()):
		var btn: Button = _action_buttons[i]
		var hover_col: Color = hover_colors[i % hover_colors.size()]
		_style_juice_button(btn, hover_col)


func _style_juice_button(btn: Button, target_hover_color: Color) -> void:
	btn.focus_mode = Control.FOCUS_NONE
	btn.set_meta("ui_sfx_bound", true)

	btn.add_theme_color_override("font_color", button_text_color)
	btn.add_theme_color_override("font_hover_color", button_text_color)
	btn.add_theme_color_override("font_pressed_color", button_text_color)
	btn.add_theme_color_override("font_focus_color", button_text_color)

	var sb := StyleBoxFlat.new()
	sb.bg_color = button_normal_color
	sb.skew = Vector2(0.0, 0.0)
	sb.border_width_left = 3
	sb.border_width_top = 3
	sb.border_width_right = 3
	sb.border_width_bottom = 3
	sb.border_color = button_shadow_color
	sb.shadow_color = button_shadow_color
	sb.shadow_size = 1
	sb.shadow_offset = Vector2(3, 3)
	sb.corner_radius_top_left = 10
	sb.corner_radius_top_right = 10
	sb.corner_radius_bottom_left = 10
	sb.corner_radius_bottom_right = 10
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8


	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb)
	btn.add_theme_stylebox_override("pressed", sb)
	btn.add_theme_stylebox_override("focus", sb)
	_btn_styleboxes[btn] = sb

	btn.resized.connect(func(): btn.pivot_offset = btn.size / 2.0)
	btn.pivot_offset = btn.size / 2.0

	btn.mouse_entered.connect(func():
		if typeof(GameManager) != TYPE_NIL:
			GameManager.play_ui_hover()
		_animate_button_hover(btn, target_hover_color, true)
	)
	btn.mouse_exited.connect(func():
		_animate_button_hover(btn, button_normal_color, false)
	)
	btn.button_down.connect(func():
		if typeof(GameManager) != TYPE_NIL:
			GameManager.play_ui_click()
		btn.pivot_offset = btn.size / 2.0
		var tw: Tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.tween_property(btn, "scale", Vector2(1.12, 0.86), 0.05)
		tw.tween_property(btn, "scale", Vector2(0.96, 1.05), 0.06)
		tw.tween_property(btn, "scale", Vector2(1.06, 1.06), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)


func _animate_button_hover(btn: Button, target_col: Color, is_hovered: bool) -> void:
	if _btn_hover_tweens.has(btn) and _btn_hover_tweens[btn] != null and _btn_hover_tweens[btn].is_running():
		_btn_hover_tweens[btn].kill()

	var sb: StyleBoxFlat = _btn_styleboxes.get(btn) as StyleBoxFlat
	var target_scale: Vector2 = Vector2(1.06, 1.06) if is_hovered else Vector2.ONE
	var target_y_offset: float = -4.0 if is_hovered else 0.0
	var target_shadow: Vector2 = Vector2(8, 8) if is_hovered else Vector2(5, 5)

	var tw: Tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.set_parallel(true)
	tw.tween_property(btn, "scale", target_scale, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(btn, "position:y", target_y_offset, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if sb != null:
		tw.tween_property(sb, "bg_color", target_col, 0.12)
		tw.tween_property(sb, "shadow_offset", target_shadow, 0.14)

	_btn_hover_tweens[btn] = tw


func show_result() -> void:
	show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	var final_score: int = GameManager.score if typeof(GameManager) != TYPE_NIL else 0
	var final_acc: float = GameManager.get_accuracy_percent() if typeof(GameManager) != TYPE_NIL else 0.0
	var final_combo: int = GameManager.max_combo if typeof(GameManager) != TYPE_NIL else 0
	var final_perfect: int = GameManager.perfect_count if typeof(GameManager) != TYPE_NIL else 0
	var final_miss: int = GameManager.miss_count if typeof(GameManager) != TYPE_NIL else 0
	var rank_text: String = GameManager.get_rank() if typeof(GameManager) != TYPE_NIL else "F"
	var failed: bool = GameManager.is_game_over if typeof(GameManager) != TYPE_NIL else false
	var track_title: String = GameManager.selected_song_title if typeof(GameManager) != TYPE_NIL else "Demo Track"

	if title_label != null:
		if failed:
			title_label.text = "STAGE FAILED!"
			title_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.40, 1.0))
		else:
			title_label.text = "STAGE CLEAR!"
			title_label.add_theme_color_override("font_color", Color(0.96, 0.94, 0.89, 1.0))

	if song_name_label != null:
		song_name_label.text = track_title

	if full_combo_badge != null:
		full_combo_badge.visible = (not failed and final_miss == 0 and final_perfect > 0)

	if rank_label != null:
		rank_label.text = rank_text
		_apply_rank_theme_color(rank_text)

	if stars_label != null:
		stars_label.text = _get_stars_string(final_acc, failed)

	if max_combo_label != null:
		max_combo_label.text = "%dX" % final_combo
	if perfect_label != null:
		perfect_label.text = str(final_perfect)
	if miss_label != null:
		miss_label.text = str(final_miss)

	# 1. แอนิเมชั่นเด้งการ์ดหลักขึ้นมา
	if panel != null:
		panel.pivot_offset = panel.size / 2.0
		panel.scale = Vector2(0.84, 0.84)
		panel.modulate.a = 0.0
		var pop_tw: Tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		pop_tw.set_parallel(true)
		pop_tw.tween_property(panel, "scale", Vector2.ONE, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		pop_tw.tween_property(panel, "modulate:a", 1.0, 0.18)

	# 2. แอนิเมชั่นตราประทับวงกลมเกรด (Rank Stamp Pop)
	if rank_circle_panel != null:
		rank_circle_panel.pivot_offset = rank_circle_panel.size / 2.0
		rank_circle_panel.scale = Vector2(1.65, 1.65)
		rank_circle_panel.modulate.a = 0.0
		var r_tw: Tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		r_tw.tween_interval(0.18)
		r_tw.parallel().tween_property(rank_circle_panel, "scale", Vector2.ONE, 0.34).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		r_tw.parallel().tween_property(rank_circle_panel, "modulate:a", 1.0, 0.15)

	# 3. แอนิเมชั่นตัวเลขนับคะแนนและหลอด Accuracy วิ่งขึ้น
	var stat_tw: Tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	stat_tw.set_parallel(true)
	if score_label != null:
		stat_tw.tween_method(
			func(val: int): score_label.text = "%06d" % val,
			0,
			final_score,
			0.85
		).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	if accuracy_label != null:
		stat_tw.tween_method(
			func(val: float): accuracy_label.text = "%.2f%%" % val,
			0.0,
			final_acc,
			0.85
		).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	if accuracy_bar != null:
		accuracy_bar.value = 0.0
		stat_tw.tween_property(accuracy_bar, "value", final_acc, 0.85).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)


func _apply_rank_theme_color(rank_text: String) -> void:
	var rank_col := Color(1.0, 0.84, 0.2, 1.0)
	match rank_text:
		"S+", "S":
			rank_col = Color(1.0, 0.84, 0.2, 1.0)  # สีทอง
		"A":
			rank_col = Color(0.38, 1.0, 0.62, 1.0) # สีเขียวมินต์
		"B":
			rank_col = Color(0.36, 0.85, 1.0, 1.0) # สีฟ้าไซเบอร์
		"C":
			rank_col = Color(1.0, 0.62, 0.25, 1.0) # สีส้ม
		_:
			rank_col = Color(1.0, 0.35, 0.42, 1.0) # สีแดง

	if rank_label != null:
		rank_label.add_theme_color_override("font_color", rank_col)
	if rank_circle_panel != null:
		var base_sb: StyleBox = rank_circle_panel.get_theme_stylebox("panel")
		if base_sb is StyleBoxFlat:
			var sb_copy: StyleBoxFlat = (base_sb as StyleBoxFlat).duplicate() as StyleBoxFlat
			sb_copy.border_color = rank_col
			sb_copy.shadow_color = Color(rank_col.r, rank_col.g, rank_col.b, 0.40)
			rank_circle_panel.add_theme_stylebox_override("panel", sb_copy)


func _get_stars_string(acc: float, failed: bool) -> String:
	if failed or acc <= 0.0:
		return "☆ ☆ ☆ ☆ ☆"
	var filled_count: int = 1
	if acc >= 95.0:
		filled_count = 5
	elif acc >= 85.0:
		filled_count = 4
	elif acc >= 70.0:
		filled_count = 3
	elif acc >= 50.0:
		filled_count = 2

	var stars_arr: PackedStringArray = PackedStringArray()
	for i in range(5):
		stars_arr.append("★" if i < filled_count else "☆")
	return " ".join(stars_arr)


func _on_retry_button_pressed() -> void:
	await get_tree().create_timer(0.08, true).timeout
	get_tree().paused = false
	if typeof(GameManager) != TYPE_NIL:
		GameManager.reset_stats()
		GameManager.stop_menu_bgm()
	if is_overlay_in_world and get_tree().current_scene != self:
		get_tree().reload_current_scene()
	else:
		get_tree().change_scene_to_file("res://Scenes/world.tscn")


func _on_song_select_button_pressed() -> void:
	await get_tree().create_timer(0.08, true).timeout
	get_tree().paused = false
	if typeof(GameManager) != TYPE_NIL:
		GameManager.reset_stats()
	get_tree().change_scene_to_file("res://Scenes/song_selection.tscn")


func _on_main_menu_button_pressed() -> void:
	await get_tree().create_timer(0.08, true).timeout
	get_tree().paused = false
	if typeof(GameManager) != TYPE_NIL:
		GameManager.reset_stats()
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
