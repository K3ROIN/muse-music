extends Control

@export_group("Song Progress Bar (เชื่อมกับ AudioStreamPlayer ในซีน world)")
@export var world_audio_player: AudioStreamPlayer = null
@export var progress_counts_down_remaining: bool = false
@export var show_remaining_time_text: bool = true

@export_group("Health & Fever Settings (ตั้งค่าหลอดเลือดและ Fever)")
@export var display_max_hp: int = 350
@export var fever_gain_per_perfect: float = 5.0
@export var fever_duration_seconds: float = 6.0

@export_group("Judgment Colors (สีตัวอักษร PERFECT / MISS ปรับใน Inspector ได้)")
@export var perfect_color: Color = Color(1.0, 0.28, 0.68, 1.0)
@export var fever_perfect_color: Color = Color(0.20, 0.95, 1.0, 1.0)
@export var miss_color: Color = Color(0.95, 0.32, 0.42, 1.0)

@onready var song_progress_bar: ProgressBar = find_child("SongProgressBar", true, false) as ProgressBar
@onready var midi_time_label: Label = find_child("MidiTimeLabel", true, false) as Label

@onready var score_label: Label = find_child("ScoreLabel", true, false) as Label
@onready var score_caption_label: Label = find_child("ScoreCaptionLabel", true, false) as Label
@onready var combo_label: Label = find_child("ComboLabel", true, false) as Label
@onready var judgment_label: Label = find_child("JudgmentLabel", true, false) as Label

@onready var bottom_status_dock: Control = find_child("BottomStatusDock", true, false) as Control
@onready var heart_badge: Control = find_child("HeartBadge", true, false) as Control
@onready var fever_bar: ProgressBar = find_child("FeverBar", true, false) as ProgressBar
@onready var health_bar: ProgressBar = find_child("HealthBar", true, false) as ProgressBar
@onready var health_value_label: Label = find_child("HealthValueLabel", true, false) as Label
@onready var fever_badge: Control = find_child("FeverBadge", true, false) as Control
@onready var fever_text_label: Label = find_child("FeverTextLabel", true, false) as Label
@onready var damage_flash: ColorRect = find_child("DamageFlash", true, false) as ColorRect
@onready var pause_button: Button = find_child("PauseButton", true, false) as Button

var _displayed_score: int = 0
var _score_tween: Tween = null
var _judgment_tween: Tween = null
var _hp_tween: Tween = null
var _fever_tween: Tween = null
var _fever_pulse_tween: Tween = null

var _current_fever: float = 0.0
var _max_fever: float = 100.0
var _is_fever_active: bool = false

var _song_length_sec: float = 0.0
var _last_playback_pos: float = 0.0


func _ready() -> void:
	if judgment_label != null:
		judgment_label.text = ""
		judgment_label.modulate.a = 0.0

	if midi_time_label != null:
		midi_time_label.visible = show_remaining_time_text

	if pause_button != null and not pause_button.pressed.is_connected(_on_pause_button_pressed):
		pause_button.pressed.connect(_on_pause_button_pressed)

	if typeof(GameManager) != TYPE_NIL:
		if GameManager.has_signal("score_changed") and not GameManager.score_changed.is_connected(_on_score_changed):
			GameManager.score_changed.connect(_on_score_changed)
		if GameManager.has_signal("stamina_changed") and not GameManager.stamina_changed.is_connected(_on_stamina_changed):
			GameManager.stamina_changed.connect(_on_stamina_changed)
		if GameManager.has_signal("fever_changed") and not GameManager.fever_changed.is_connected(_on_fever_changed):
			GameManager.fever_changed.connect(_on_fever_changed)

		var init_hp: float = float(GameManager.get("current_stamina")) if "current_stamina" in GameManager else 350.0
		var init_max_hp: float = float(GameManager.get("max_stamina")) if "max_stamina" in GameManager else 350.0
		_update_health_bar_ui(init_hp, init_max_hp, false)

	_update_fever_bar_ui(0.0, _max_fever)
	_resolve_world_audio_player()


func _process(delta: float) -> void:
	_update_song_progress_from_audio_player()

	if _is_fever_active and (typeof(GameManager) == TYPE_NIL or not GameManager.has_signal("fever_changed")):
		var drain_rate: float = _max_fever / maxf(0.5, fever_duration_seconds)
		_current_fever = maxf(0.0, _current_fever - drain_rate * delta)
		if fever_bar != null:
			fever_bar.value = _current_fever
		if _current_fever <= 0.0:
			_set_fever_mode_visual(false)


func _resolve_world_audio_player() -> void:
	if world_audio_player != null and is_instance_valid(world_audio_player) and world_audio_player.stream != null:
		_sync_bar_max_to_stream(world_audio_player.stream)
		return

	var scene_root: Node = get_tree().current_scene if get_tree() != null else null
	if scene_root == null:
		return

	for node in scene_root.find_children("*", "Node", true, false):
		if "music_player" in node:
			var mp: AudioStreamPlayer = node.get("music_player") as AudioStreamPlayer
			if mp != null and is_instance_valid(mp) and mp.stream != null:
				world_audio_player = mp
				_sync_bar_max_to_stream(mp.stream)
				return

	var fallback_player: AudioStreamPlayer = null
	for child in scene_root.find_children("*", "AudioStreamPlayer", true, false):
		var player: AudioStreamPlayer = child as AudioStreamPlayer
		if player == null or player.stream == null:
			continue
		if player.name.begins_with("UISFXPlayer") or player.name == "MenuBGMPlayer":
			continue

		var stream_path: String = player.stream.resource_path.to_lower()
		if player.playing or stream_path.ends_with(".ogg") or stream_path.ends_with(".mp3") or player.stream is AudioStreamOggVorbis or player.stream is AudioStreamMP3:
			world_audio_player = player
			_sync_bar_max_to_stream(player.stream)
			return

		if fallback_player == null:
			fallback_player = player

	if fallback_player != null:
		world_audio_player = fallback_player
		_sync_bar_max_to_stream(fallback_player.stream)


func _sync_bar_max_to_stream(stream: AudioStream) -> void:
	if stream == null:
		return
	var len_sec: float = stream.get_length()
	if len_sec <= 0.0:
		return

	_song_length_sec = len_sec
	if song_progress_bar != null:
		song_progress_bar.min_value = 0.0
		song_progress_bar.max_value = _song_length_sec
		song_progress_bar.step = 0.0


func _update_song_progress_from_audio_player() -> void:
	if world_audio_player == null or not is_instance_valid(world_audio_player) or world_audio_player.stream == null:
		_resolve_world_audio_player()
		if world_audio_player == null or world_audio_player.stream == null:
			return

	var stream_len: float = world_audio_player.stream.get_length()
	if stream_len <= 0.0:
		return

	if absf(_song_length_sec - stream_len) > 0.001:
		_sync_bar_max_to_stream(world_audio_player.stream)

	var current_pos: float = _last_playback_pos
	if world_audio_player.playing:
		current_pos = world_audio_player.get_playback_position() + AudioServer.get_time_since_last_mix()
		current_pos = clampf(current_pos, 0.0, _song_length_sec)
		_last_playback_pos = current_pos
	elif not world_audio_player.stream_paused and _last_playback_pos >= _song_length_sec * 0.98:
		current_pos = _song_length_sec


	if song_progress_bar != null:
		song_progress_bar.max_value = _song_length_sec
		song_progress_bar.step = 0.01
		if progress_counts_down_remaining:
			song_progress_bar.value = maxf(0.0, _song_length_sec - current_pos)
		else:
			song_progress_bar.value = current_pos

	if midi_time_label != null and show_remaining_time_text:
		var clamped_time: float = clampf(current_pos, 0.0, _song_length_sec)
		var elapsed_int: int = int(round(clamped_time))
		var mins: int = int(floor(float(elapsed_int) / 60.0))
		var secs: int = elapsed_int % 60
		midi_time_label.text = "%02d:%02d" % [mins, secs]


func _on_score_changed(new_score: int, new_combo: int, judgment: String) -> void:
	if score_label != null:
		if _score_tween != null and _score_tween.is_running():
			_score_tween.kill()
		var start_val: int = _displayed_score
		_displayed_score = new_score
		score_label.pivot_offset = Vector2(0.0, score_label.size.y * 0.5)
		score_label.scale = Vector2(1.14, 1.14)

		_score_tween = create_tween()
		_score_tween.set_parallel(true)
		_score_tween.tween_method(
			func(val: int): score_label.text = str(val),
			start_val,
			new_score,
			0.14
		)
		_score_tween.tween_property(score_label, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	if combo_label != null:
		if new_combo > 1:
			combo_label.visible = true
			combo_label.text = "%d COMBO" % new_combo
			combo_label.pivot_offset = Vector2(0.0, combo_label.size.y * 0.5)
			combo_label.scale = Vector2(1.22, 1.22)
			var c_tw: Tween = create_tween()
			c_tw.tween_property(combo_label, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		else:
			combo_label.visible = false

	if judgment != "":
		_show_judgment_popup(judgment)

	if typeof(GameManager) == TYPE_NIL or not GameManager.has_signal("fever_changed"):
		if judgment == "PERFECT" and not _is_fever_active:
			_current_fever = minf(_max_fever, _current_fever + fever_gain_per_perfect)
			_update_fever_bar_ui(_current_fever, _max_fever)
			if _current_fever >= _max_fever:
				_set_fever_mode_visual(true)


func _show_judgment_popup(judgment: String) -> void:
	if judgment_label == null:
		return

	if _judgment_tween != null and _judgment_tween.is_running():
		_judgment_tween.kill()

	judgment_label.pivot_offset = judgment_label.size / 2.0

	if judgment == "PERFECT":
		judgment_label.text = "PERFECT"
		var col: Color = fever_perfect_color if _is_fever_active else perfect_color
		judgment_label.add_theme_color_override("font_color", col)
	else:
		judgment_label.text = judgment
		judgment_label.add_theme_color_override("font_color", miss_color)

	judgment_label.scale = Vector2(0.55, 0.55)
	judgment_label.modulate.a = 1.0

	_judgment_tween = create_tween()
	_judgment_tween.tween_property(judgment_label, "scale", Vector2(1.12, 1.12), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_judgment_tween.tween_property(judgment_label, "scale", Vector2.ONE, 0.06)
	_judgment_tween.tween_interval(0.22)
	_judgment_tween.tween_property(judgment_label, "modulate:a", 0.0, 0.15)


func _on_stamina_changed(current_hp: float, max_hp: float) -> void:
	var prev_ratio: float = 1.0
	if health_bar != null and health_bar.max_value > 0.0:
		prev_ratio = health_bar.value / health_bar.max_value
	var new_ratio: float = clampf(current_hp / maxf(1.0, max_hp), 0.0, 1.0)
	var took_damage: bool = new_ratio < prev_ratio - 0.001

	_update_health_bar_ui(current_hp, max_hp, took_damage)


func _update_health_bar_ui(current_hp: float, max_hp: float, took_damage: bool) -> void:
	var safe_max: float = maxf(1.0, max_hp)
	var ratio: float = clampf(current_hp / safe_max, 0.0, 1.0)
	var scaled_current: int = int(round(ratio * float(display_max_hp)))

	if health_bar != null:
		health_bar.max_value = float(display_max_hp)
		if _hp_tween != null and _hp_tween.is_running():
			_hp_tween.kill()
		_hp_tween = create_tween()
		_hp_tween.tween_property(health_bar, "value", float(scaled_current), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	if health_value_label != null:
		health_value_label.text = "%d/%d" % [scaled_current, display_max_hp]
		health_value_label.visible = false

	if took_damage:
		_play_damage_feedback()


func _play_damage_feedback() -> void:
	if damage_flash != null:
		damage_flash.color = Color(1.0, 0.15, 0.35, 0.28)
		var f_tw: Tween = create_tween()
		f_tw.tween_property(damage_flash, "color:a", 0.0, 0.22)

	if heart_badge != null:
		heart_badge.pivot_offset = heart_badge.size / 2.0
		heart_badge.scale = Vector2(1.3, 0.75)
		var h_tw: Tween = create_tween()
		h_tw.tween_property(heart_badge, "scale", Vector2.ONE, 0.20).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _on_fever_changed(current_fever: float, max_fever: float, fever_active: bool) -> void:
	_current_fever = current_fever
	_max_fever = maxf(1.0, max_fever)
	_update_fever_bar_ui(_current_fever, _max_fever)
	if fever_active != _is_fever_active:
		_set_fever_mode_visual(fever_active)


func _update_fever_bar_ui(current_fever: float, max_fever: float) -> void:
	if fever_bar == null:
		return
	fever_bar.max_value = maxf(1.0, max_fever)
	if _fever_tween != null and _fever_tween.is_running():
		_fever_tween.kill()
	_fever_tween = create_tween()
	_fever_tween.tween_property(fever_bar, "value", clampf(current_fever, 0.0, max_fever), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _set_fever_mode_visual(active: bool) -> void:
	_is_fever_active = active
	if _fever_pulse_tween != null and _fever_pulse_tween.is_running():
		_fever_pulse_tween.kill()

	if fever_badge == null:
		return

	fever_badge.pivot_offset = fever_badge.size / 2.0
	if active:
		if fever_text_label != null:
			fever_text_label.text = "FEVER!"
		_fever_pulse_tween = create_tween().set_loops()
		_fever_pulse_tween.tween_property(fever_badge, "scale", Vector2(1.12, 1.12), 0.22).set_trans(Tween.TRANS_SINE)
		_fever_pulse_tween.tween_property(fever_badge, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_SINE)
	else:
		fever_badge.scale = Vector2.ONE
		if fever_text_label != null:
			fever_text_label.text = "FEVER"


func _on_pause_button_pressed() -> void:
	if typeof(GameManager) != TYPE_NIL and GameManager.has_method("play_ui_click"):
		GameManager.play_ui_click()
	if get_tree() != null and get_tree().current_scene != null:
		var pause_menu: Node = get_tree().current_scene.find_child("PauseMenu", true, false)
		if pause_menu != null and pause_menu.has_method("toggle_pause"):
			pause_menu.call("toggle_pause")
			return
	var ev := InputEventAction.new()
	ev.action = &"pause_game"
	ev.pressed = true
	Input.parse_input_event(ev)
