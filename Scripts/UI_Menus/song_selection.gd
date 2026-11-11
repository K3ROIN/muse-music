extends Control

# ==============================================================================
# Just Dance Style Carousel Song Selection (res://Scripts/song_selection.gd)
# ถอดแบบแอนิเมชั่นและรายละเอียดจากวิดีโอ "Screen Recording 2026-11-10 153724.mp4":
# ------------------------------------------------------------------------------
# 1. แอนิเมชั่นตอนเข้าฉากจาก Main Menu (_play_scene_entry_animation):
#    - แผ่นวงกลมทั้ง 5 วงจะกางออก (Fan-Out) จากจุดกึ่งกลางไปยังตำแหน่งซ้าย-ขวาแบบนุ่มนวล
#    - แถบชื่อเพลงด้านบนและปุ่มมุมซ้าย/ขวาล่างสไลด์เข้ามาพร้อมกัน
# 2. แอนิเมชั่นตอนกดเลื่อนเพลงซ้าย-ขวา (เหมือนในคลิปวินาทีที่ 0:02, 0:12, 0:19, 0:28):
#    - ขณะที่แผ่นวงกลมกำลังเลื่อนสลับตำแหน่ง ขอบเรืองแสงสีขาว ไอคอน ▶ และดาวคะแนนด้านล่าง
#      จะซ่อนตัวชั่วคราว (เหมือนในคลิปจังหวะที่แผ่นกำลังเลื่อน)
#    - แผ่นวงกลมแต่ละวงจะเลื่อนตำแหน่ง (position) และย่อ/ขยายขนาด (size) ข้ามไปยังช่องถัดไปจริงๆ
#    - เมื่อแผ่นใหม่เข้าสู่ตรงกลางเสร็จ ขอบวงแหวนสีขาวเรืองแสง ไอคอน ▶ และดาวคะแนน (★ ★ ★ ★ + คะแนน)
#      จะสว่างวาบขึ้นมาพร้อมกัน!
# 3. เพลง BGM จากหน้า Main Menu เล่นต่อเนื่องไม่สะดุด และหยุดเฉพาะตอนกดเข้าเล่นเพลง
# ==============================================================================

@export_group("Songs Catalog (แก้ไข/เพิ่มเพลงใน Inspector ได้)")
@export var song_titles: Array[String] = [
	"Talk (Demo Track)",
	"After the Battle",
	"Neon Starlight",
	"Pastel Runner",
	"Cyber Groove"
]
@export var song_artists: Array[String] = [
	"K3ROIN",
	"Muse Rhythm",
	"Synthwave Collective",
	"Duet Cats Studio",
	"Future Bass Project"
]
@export var song_audio_paths: Array[String] = [
	"res://Audios/1-18. Talk.ogg",
	"res://Audios/BGM/1-17. After the Battle.mp3",
	"res://Audios/1-18. Talk.ogg",
	"res://Audios/1-18. Talk.ogg",
	"res://Audios/1-18. Talk.ogg"
]
@export var song_midi_paths: Array[String] = [
	"res://Audios/song1.mid",
	"res://Audios/song1.mid",
	"res://Audios/song1.mid",
	"res://Audios/song1.mid",
	"res://Audios/song1.mid"
]
@export var song_disc_colors: Array[Color] = [
	Color(0.12, 0.62, 0.92, 1.0), # ฟ้าสว่าง
	Color(0.85, 0.20, 0.52, 1.0), # ชมพูบานเย็น
	Color(0.52, 0.22, 0.88, 1.0), # ม่วงนีออน
	Color(0.92, 0.45, 0.15, 1.0), # ส้มทอง
	Color(0.15, 0.78, 0.58, 1.0)  # เขียวมินต์
]
@export var song_difficulty_gears: Array[String] = [
	"⚙ ⚙ ○",
	"⚙ ○ ○",
	"⚙ ⚙ ⚙",
	"⚙ ⚙ ○",
	"⚙ ⚙ ⚙"
]
@export var song_sweat_icons: Array[String] = [
	"💧 ○ ○",
	"💧 ○ ○",
	"💧 💧 💧",
	"💧 💧 ○",
	"💧 💧 ○"
]
@export var song_star_ratings: Array[String] = [
	"★ ★ ★ ★ ☆",
	"★ ★ ★ ☆ ☆",
	"★ ★ ★ ★ ★",
	"★ ★ ★ ★ ☆",
	"★ ★ ★ ☆ ☆"
]
@export var song_high_scores: Array[String] = [
	"11047   K3R",
	"9909   K3R",
	"12450   K3R",
	"8640   K3R",
	"10200   K3R"
]
@export var song_cover_textures: Array[Texture2D] = []

@onready var header_vbox: VBoxContainer = find_child("HeaderVBox", true, false) as VBoxContainer
@onready var song_title_label: Label = find_child("SongTitleLabel", true, false) as Label
@onready var artist_label: Label = find_child("ArtistLabel", true, false) as Label
@onready var diff_stars_label: Label = find_child("DiffStarsLabel", true, false) as Label
@onready var sweat_drops_label: Label = find_child("SweatDropsLabel", true, false) as Label

@onready var carousel_stage: Control = find_child("CarouselStage", true, false) as Control
@onready var disc_left_2: Button = find_child("DiscLeft2", true, false) as Button
@onready var disc_left_1: Button = find_child("DiscLeft1", true, false) as Button
@onready var disc_center: Button = find_child("DiscCenter", true, false) as Button
@onready var disc_right_1: Button = find_child("DiscRight1", true, false) as Button
@onready var disc_right_2: Button = find_child("DiscRight2", true, false) as Button

@onready var center_cover_label: Label = find_child("CoverLabel", true, false) as Label
@onready var center_focus_overlay: Control = find_child("CenterFocusOverlay", true, false) as Control
@onready var score_stars_vbox: Control = find_child("ScoreStarsVBox", true, false) as Control
@onready var stars_label: Label = find_child("StarsLabel", true, false) as Label
@onready var high_score_label: Label = find_child("HighScoreLabel", true, false) as Label

@onready var prev_song_btn: Button = find_child("PrevSongBtn", true, false) as Button
@onready var next_song_btn: Button = find_child("NextSongBtn", true, false) as Button
@onready var bottom_left_nav: Control = find_child("BottomLeftNav", true, false) as Control
@onready var bottom_right_nav: Control = find_child("BottomRightNav", true, false) as Control
@onready var back_btn: Button = find_child("BackButton", true, false) as Button
@onready var collection_btn: Button = find_child("CollectionButton", true, false) as Button

var current_index: int = 0
var _disc_buttons: Array[Button] = []
var _slot_positions: Array[Vector2] = []
var _slot_sizes: Array[Vector2] = []
var _slot_z_indices: Array[int] = [1, 5, 10, 5, 1]
var _is_sliding: bool = false
var _carousel_tween: Tween = null


func _ready() -> void:
	# ให้เพลง BGM จากหน้า Main Menu เล่นต่อเนื่องในหน้านี้โดยไม่เริ่มใหม่
	if typeof(GameManager) != TYPE_NIL:
		GameManager.play_menu_bgm()
		current_index = GameManager.selected_song_index

	_disc_buttons = [disc_left_2, disc_left_1, disc_center, disc_right_1, disc_right_2]
	_record_slot_transforms()
	_connect_signals_safely()
	_attach_hover_animations()
	_refresh_disc_contents_and_header()
	_play_scene_entry_animation()


func _record_slot_transforms() -> void:
	_slot_positions.clear()
	_slot_sizes.clear()
	for btn in _disc_buttons:
		if btn != null:
			_slot_positions.append(btn.position)
			_slot_sizes.append(btn.size)
		else:
			_slot_positions.append(Vector2.ZERO)
			_slot_sizes.append(Vector2(160, 160))


func _connect_signals_safely() -> void:
	if disc_left_2 != null and not disc_left_2.pressed.is_connected(_on_disc_left_2_pressed):
		disc_left_2.pressed.connect(_on_disc_left_2_pressed)
	if disc_left_1 != null and not disc_left_1.pressed.is_connected(_on_disc_left_1_pressed):
		disc_left_1.pressed.connect(_on_disc_left_1_pressed)
	if disc_center != null and not disc_center.pressed.is_connected(_on_disc_center_pressed):
		disc_center.pressed.connect(_on_disc_center_pressed)
	if disc_right_1 != null and not disc_right_1.pressed.is_connected(_on_disc_right_1_pressed):
		disc_right_1.pressed.connect(_on_disc_right_1_pressed)
	if disc_right_2 != null and not disc_right_2.pressed.is_connected(_on_disc_right_2_pressed):
		disc_right_2.pressed.connect(_on_disc_right_2_pressed)

	if prev_song_btn != null and not prev_song_btn.pressed.is_connected(_on_prev_song_pressed):
		prev_song_btn.pressed.connect(_on_prev_song_pressed)
	if next_song_btn != null and not next_song_btn.pressed.is_connected(_on_next_song_pressed):
		next_song_btn.pressed.connect(_on_next_song_pressed)
	if back_btn != null and not back_btn.pressed.is_connected(_on_back_button_pressed):
		back_btn.pressed.connect(_on_back_button_pressed)
	if collection_btn != null and not collection_btn.pressed.is_connected(_on_collection_button_pressed):
		collection_btn.pressed.connect(_on_collection_button_pressed)


func _attach_hover_animations() -> void:
	for btn_node in [prev_song_btn, next_song_btn, back_btn, collection_btn, disc_center]:
		var btn: Button = btn_node as Button
		if btn == null:
			continue
		btn.set_meta("ui_sfx_bound", true)
		btn.resized.connect(func(): btn.pivot_offset = btn.size / 2.0)
		btn.pivot_offset = btn.size / 2.0

		btn.mouse_entered.connect(func():
			if _is_sliding:
				return
			if typeof(GameManager) != TYPE_NIL:
				GameManager.play_ui_hover()
			var tw: Tween = create_tween()
			tw.tween_property(btn, "scale", Vector2(1.06, 1.06), 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		)
		btn.mouse_exited.connect(func():
			if _is_sliding:
				return
			var tw: Tween = create_tween()
			tw.tween_property(btn, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		)


# ==============================================================================
# 1. แอนิเมชั่นตอนเปิดเข้าหน้า Song Selection จากหน้า Main Menu
# ==============================================================================
func _play_scene_entry_animation() -> void:
	if _slot_positions.size() < 5:
		return

	var center_pos: Vector2 = _slot_positions[2]
	var center_sz: Vector2 = _slot_sizes[2]

	if center_focus_overlay != null:
		center_focus_overlay.modulate.a = 0.0
	if score_stars_vbox != null:
		score_stars_vbox.modulate.a = 0.0

	if header_vbox != null:
		var base_hy: float = header_vbox.position.y
		header_vbox.position.y = base_hy - 90.0
		header_vbox.modulate.a = 0.0
		var h_tw: Tween = create_tween()
		h_tw.set_parallel(true)
		h_tw.tween_property(header_vbox, "position:y", base_hy, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		h_tw.tween_property(header_vbox, "modulate:a", 1.0, 0.22)

	# แผ่นวงกลมทั้ง 5 กางออก (Fan-Out) จากจุดกึ่งกลางไปยังตำแหน่งของตัวเอง
	var entry_tw: Tween = create_tween()
	entry_tw.set_parallel(true)

	for i in range(_disc_buttons.size()):
		var btn: Button = _disc_buttons[i]
		if btn == null:
			continue
		var target_pos: Vector2 = _slot_positions[i]
		var target_sz: Vector2 = _slot_sizes[i]
		btn.position = center_pos + (center_sz - target_sz) * 0.5
		btn.modulate.a = 0.0
		btn.scale = Vector2(0.75, 0.75)

		var delay_s: float = absf(float(i - 2)) * 0.055
		entry_tw.tween_property(btn, "position", target_pos, 0.34).set_delay(delay_s).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		entry_tw.tween_property(btn, "scale", Vector2.ONE, 0.34).set_delay(delay_s).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		entry_tw.tween_property(btn, "modulate:a", 1.0, 0.20).set_delay(delay_s)

	if bottom_left_nav != null:
		var bl_x: float = bottom_left_nav.position.x
		bottom_left_nav.position.x = bl_x - 160.0
		entry_tw.tween_property(bottom_left_nav, "position:x", bl_x, 0.30).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	if bottom_right_nav != null:
		var br_x: float = bottom_right_nav.position.x
		bottom_right_nav.position.x = br_x + 160.0
		entry_tw.tween_property(bottom_right_nav, "position:x", br_x, 0.30).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	entry_tw.chain().tween_callback(func():
		_reveal_center_focus_and_stars()
	)


# ==============================================================================
# 2. แอนิเมชั่นเลื่อนแผ่นวงกลมสลับตำแหน่งซ้าย-ขวา (ตามวิดีโอ 0:12, 0:19, 0:28)
# ==============================================================================
func _shift_carousel(step: int) -> void:
	if _is_sliding or step == 0 or _slot_positions.size() < 5:
		return
	_is_sliding = true

	var count: int = max(song_titles.size(), 1)
	current_index = posmod(current_index + step, count)
	if typeof(GameManager) != TYPE_NIL:
		GameManager.play_ui_click()
		GameManager.selected_song_index = current_index

	# 1. ซ่อนวงแหวนสีขาวตรงกลาง, ไอคอน ▶ และดาวคะแนนทันทีที่เริ่มเลื่อน (เหมือนในคลิป)
	if center_focus_overlay != null:
		center_focus_overlay.modulate.a = 0.0
	if score_stars_vbox != null:
		score_stars_vbox.modulate.a = 0.0

	# 2. อัปเดตสีและชื่อเพลงของแผ่นวงกลมเป็นชุดใหม่ แล้ววางจุดเริ่มต้นที่ช่องก่อนหน้า
	#    เพื่อให้เห็นแผ่นวงกลมเลื่อนและขยาย/ย่อขนาดข้ามช่องมายังตำแหน่งใหม่อย่างต่อเนื่อง
	_refresh_disc_contents_and_header()

	if _carousel_tween != null and _carousel_tween.is_running():
		_carousel_tween.kill()
	_carousel_tween = create_tween()
	_carousel_tween.set_parallel(true)

	var dir_sign: int = 1 if step > 0 else -1
	for i in range(_disc_buttons.size()):
		var btn: Button = _disc_buttons[i]
		if btn == null:
			continue

		var target_pos: Vector2 = _slot_positions[i]
		var target_sz: Vector2 = _slot_sizes[i]
		var from_slot: int = i + dir_sign

		if from_slot >= 0 and from_slot < 5:
			btn.position = _slot_positions[from_slot]
			btn.size = _slot_sizes[from_slot]
			btn.custom_minimum_size = _slot_sizes[from_slot]
		else:
			var edge_offset: float = 160.0 * float(dir_sign)
			btn.position = target_pos + Vector2(edge_offset, 20.0)
			btn.size = target_sz * 0.8
			btn.custom_minimum_size = target_sz * 0.8

		btn.scale = Vector2.ONE
		btn.z_index = _slot_z_indices[i]

		_carousel_tween.tween_property(btn, "position", target_pos, 0.24).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_carousel_tween.tween_property(btn, "size", target_sz, 0.24).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_carousel_tween.tween_property(btn, "custom_minimum_size", target_sz, 0.24).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# 3. เมื่อแผ่นเลื่อนเข้าตรงกลางเสร็จ ให้แสดงวงแหวนเรืองแสงสีขาว ไอคอน ▶ และดาวคะแนนขึ้นมา
	_carousel_tween.chain().tween_callback(func():
		_is_sliding = false
		_reveal_center_focus_and_stars()
	)


func _reveal_center_focus_and_stars() -> void:
	var tw: Tween = create_tween()
	tw.set_parallel(true)
	if center_focus_overlay != null:
		center_focus_overlay.pivot_offset = center_focus_overlay.size / 2.0
		center_focus_overlay.scale = Vector2(0.92, 0.92)
		tw.tween_property(center_focus_overlay, "modulate:a", 1.0, 0.14)
		tw.tween_property(center_focus_overlay, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if score_stars_vbox != null:
		tw.tween_property(score_stars_vbox, "modulate:a", 1.0, 0.16)


func _refresh_disc_contents_and_header() -> void:
	var count: int = max(song_titles.size(), 1)
	current_index = posmod(current_index, count)

	var cur_title: String = song_titles[current_index] if current_index < song_titles.size() else "Track"
	var cur_artist: String = song_artists[current_index] if current_index < song_artists.size() else ""
	if song_title_label != null:
		song_title_label.text = cur_title
	if artist_label != null:
		artist_label.text = cur_artist
	if diff_stars_label != null and current_index < song_difficulty_gears.size():
		diff_stars_label.text = song_difficulty_gears[current_index]
	if sweat_drops_label != null and current_index < song_sweat_icons.size():
		sweat_drops_label.text = song_sweat_icons[current_index]
	if center_cover_label != null:
		center_cover_label.text = cur_title
	if stars_label != null and current_index < song_star_ratings.size():
		stars_label.text = song_star_ratings[current_index]
	if high_score_label != null and current_index < song_high_scores.size():
		high_score_label.text = song_high_scores[current_index]

	var offsets: Array[int] = [-2, -1, 0, 1, 2]
	for i in range(_disc_buttons.size()):
		var btn: Button = _disc_buttons[i]
		if btn == null:
			continue
		var song_idx: int = posmod(current_index + offsets[i], count)
		var s_title: String = song_titles[song_idx] if song_idx < song_titles.size() else ("Song %d" % (song_idx + 1))
		var disc_col: Color = song_disc_colors[song_idx % song_disc_colors.size()] if not song_disc_colors.is_empty() else Color(0.12, 0.62, 0.92)

		if offsets[i] != 0:
			btn.text = s_title
		else:
			btn.text = ""

		var base_sb: StyleBox = btn.get_theme_stylebox("normal")
		if base_sb is StyleBoxFlat:
			var sb_copy: StyleBoxFlat = (base_sb as StyleBoxFlat).duplicate() as StyleBoxFlat
			var darken_amount: float = 0.0 if offsets[i] == 0 else (0.18 if abs(offsets[i]) == 1 else 0.35)
			sb_copy.bg_color = disc_col.darkened(darken_amount)
			btn.add_theme_stylebox_override("normal", sb_copy)
			btn.add_theme_stylebox_override("hover", sb_copy)
			btn.add_theme_stylebox_override("pressed", sb_copy)

		if song_idx < song_cover_textures.size() and song_cover_textures[song_idx] != null:
			btn.icon = song_cover_textures[song_idx]
			btn.expand_icon = true


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var k: int = int(event.physical_keycode) if event.physical_keycode != KEY_NONE else int(event.keycode)
		if k == int(KEY_LEFT) or k == int(KEY_A):
			get_viewport().set_input_as_handled()
			_shift_carousel(-1)
		elif k == int(KEY_RIGHT) or k == int(KEY_D):
			get_viewport().set_input_as_handled()
			_shift_carousel(1)
		elif k == int(KEY_ENTER) or k == int(KEY_KP_ENTER) or k == int(KEY_SPACE):
			get_viewport().set_input_as_handled()
			_start_selected_song()
		elif k == int(KEY_ESCAPE):
			get_viewport().set_input_as_handled()
			_on_back_button_pressed()


func _on_disc_left_2_pressed() -> void:
	_shift_carousel(-2)


func _on_disc_left_1_pressed() -> void:
	_shift_carousel(-1)


func _on_disc_right_1_pressed() -> void:
	_shift_carousel(1)


func _on_disc_right_2_pressed() -> void:
	_shift_carousel(2)


func _on_prev_song_pressed() -> void:
	_shift_carousel(-1)


func _on_next_song_pressed() -> void:
	_shift_carousel(1)


func _on_collection_button_pressed() -> void:
	_shift_carousel(1)


func _on_disc_center_pressed() -> void:
	if not _is_sliding:
		_start_selected_song()


func _on_song_1_button_pressed() -> void:
	_start_selected_song()


func _start_selected_song() -> void:
	if typeof(GameManager) != TYPE_NIL:
		GameManager.selected_song_index = current_index
		if current_index < song_titles.size():
			GameManager.selected_song_title = song_titles[current_index]
		if current_index < song_audio_paths.size():
			GameManager.selected_song_audio_path = song_audio_paths[current_index]
		if current_index < song_midi_paths.size():
			GameManager.selected_song_midi_path = song_midi_paths[current_index]

		GameManager.stop_menu_bgm()
		GameManager.play_song_selected()

	get_tree().change_scene_to_file("res://Scenes/world.tscn")


func _on_back_button_pressed() -> void:
	if typeof(GameManager) != TYPE_NIL:
		GameManager.play_ui_click()
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
