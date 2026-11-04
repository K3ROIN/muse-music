extends Control

const CONFIG_PATH: String = "user://settings.cfg"

static var key_lane_left: Key = KEY_F
static var key_lane_right: Key = KEY_J
static var key_pause: Key = KEY_ESCAPE
static var custom_audio_offset_sec: float = 0.0

const RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1152, 648),
	Vector2i(1280, 720),
	Vector2i(1360, 768),
	Vector2i(1920, 1080)
]

const FPS_VALUES: Array[int] = [60, 120, 144, 0]
const FPS_LABELS: Array[String] = ["60 FPS", "120 FPS", "144 FPS", "Unlimited"]

const TAB_WIDTH_EXPANDED: float = 220.0
const TAB_WIDTH_COLLAPSED: float = 84.0

var _config := ConfigFile.new()

# โหนดแถบ Ribbon และแท็บทั้ง 3 หมวด
@onready var ribbon_bar: Control = find_child("RibbonBar", true, false) as Control
@onready var back_btn: Button = find_child("BackButton", true, false) as Button
@onready var prev_tab_btn: Button = find_child("PrevTabBtn", true, false) as Button
@onready var next_tab_btn: Button = find_child("NextTabBtn", true, false) as Button
@onready var tab_display_btn: Button = find_child("TabDisplayBtn", true, false) as Button
@onready var tab_audio_btn: Button = find_child("TabAudioBtn", true, false) as Button
@onready var tab_controls_btn: Button = find_child("TabControlsBtn", true, false) as Button

# โหนดหน้าเนื้อหาทั้ง 3 หมวด
@onready var display_page: Control = find_child("DisplayPage", true, false) as Control
@onready var audio_page: Control = find_child("AudioPage", true, false) as Control
@onready var controls_page: Control = find_child("ControlsPage", true, false) as Control

# โหนดหมวด DISPLAY
@onready var res_option: OptionButton = find_child("ResOption", true, false) as OptionButton
@onready var screen_prev_btn: Button = find_child("ScreenPrevBtn", true, false) as Button
@onready var screen_next_btn: Button = find_child("ScreenNextBtn", true, false) as Button
@onready var screen_mode_val: Label = find_child("ScreenModeValue", true, false) as Label
@onready var fps_prev_btn: Button = find_child("FPSPrevBtn", true, false) as Button
@onready var fps_next_btn: Button = find_child("FPSNextBtn", true, false) as Button
@onready var fps_val_lbl: Label = find_child("FPSValue", true, false) as Label
@onready var vsync_on_check: CheckBox = find_child("VsyncOnCheck", true, false) as CheckBox
@onready var vsync_off_check: CheckBox = find_child("VsyncOffCheck", true, false) as CheckBox
@onready var fx_low_check: CheckBox = find_child("FXLowCheck", true, false) as CheckBox
@onready var fx_high_check: CheckBox = find_child("FXHighCheck", true, false) as CheckBox

# โหนดหมวด AUDIO
@onready var master_title_lbl: Label = find_child("MasterTitle", true, false) as Label
@onready var master_slider: HSlider = find_child("MasterSlider", true, false) as HSlider
@onready var master_minus_btn: Button = find_child("MasterMinusBtn", true, false) as Button
@onready var master_plus_btn: Button = find_child("MasterPlusBtn", true, false) as Button

@onready var music_title_lbl: Label = find_child("MusicTitle", true, false) as Label
@onready var music_slider: HSlider = find_child("MusicSlider", true, false) as HSlider
@onready var music_minus_btn: Button = find_child("MusicMinusBtn", true, false) as Button
@onready var music_plus_btn: Button = find_child("MusicPlusBtn", true, false) as Button

@onready var sfx_title_lbl: Label = find_child("SFXTitle", true, false) as Label
@onready var sfx_slider: HSlider = find_child("SFXSlider", true, false) as HSlider
@onready var sfx_minus_btn: Button = find_child("SFXMinusBtn", true, false) as Button
@onready var sfx_plus_btn: Button = find_child("SFXPlusBtn", true, false) as Button

@onready var offset_minus_btn: Button = find_child("OffsetMinusBtn", true, false) as Button
@onready var offset_plus_btn: Button = find_child("OffsetPlusBtn", true, false) as Button
@onready var offset_val_lbl: Label = find_child("OffsetValueLabel", true, false) as Label
@onready var bgm_on_check: CheckBox = find_child("BGMOnCheck", true, false) as CheckBox
@onready var bgm_off_check: CheckBox = find_child("BGMOffCheck", true, false) as CheckBox

# โหนดหมวด CONTROLS & ปุ่ม Reset
@onready var left_key_btn: Button = find_child("LeftKeyBtn", true, false) as Button
@onready var right_key_btn: Button = find_child("RightKeyBtn", true, false) as Button
@onready var pause_key_btn: Button = find_child("PauseKeyBtn", true, false) as Button
@onready var reset_default_btn: Button = find_child("ResetDefaultButton", true, false) as Button

var _current_tab_idx: int = 0
var _tab_buttons: Array[Button] = []
var _tab_pages: Array[Control] = []
var _tab_full_titles: Array[String] = ["⚙  DISPLAY", "🔊  AUDIO", "🎮  CONTROLS"]
var _tab_short_icons: Array[String] = ["⚙", "🔊", "🎮"]

var _style_tab_active := StyleBoxFlat.new()
var _style_tab_inactive := StyleBoxFlat.new()

var _is_fullscreen: bool = false
var _fps_index: int = 0
var _vsync_enabled: bool = true
var _high_quality_fx: bool = true
var _bgm_enabled: bool = true
var _offset_ms: int = 0
var _waiting_for_action: String = ""
var _is_loading_config: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_audio_buses_exist()
	_init_tab_styles()
	_init_input_map()
	_connect_all_signals()
	_attach_button_hover_effects()
	load_settings()
	_switch_section_tab(0, false)


func open_settings() -> void:
	_waiting_for_action = ""
	_route_all_music_players_in_tree()
	show()

	if ribbon_bar:
		ribbon_bar.position.x = -get_viewport_rect().size.x
		var r_tw: Tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		r_tw.tween_property(ribbon_bar, "position:x", 0.0, 0.28).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)

	_switch_section_tab(_current_tab_idx, false)


func close_settings() -> void:
	_waiting_for_action = ""
	save_settings()
	if typeof(GameManager) != TYPE_NIL:
		GameManager.play_close_settings()

	if ribbon_bar:
		var r_tw: Tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		r_tw.tween_property(ribbon_bar, "position:x", -get_viewport_rect().size.x, 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		r_tw.chain().tween_callback(func():
			ribbon_bar.position.x = 0.0
			if get_tree().current_scene == self:
				get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
			else:
				hide()
		)
	else:
		hide()


func _init_tab_styles() -> void:
	_style_tab_active.bg_color = Color("#ff2288")
	_style_tab_active.skew = Vector2(0.32, 0.0)
	_style_tab_active.border_width_left = 3
	_style_tab_active.border_width_right = 3
	_style_tab_active.border_color = Color("#9e004f")

	_style_tab_inactive.bg_color = Color("#c70067")
	_style_tab_inactive.skew = Vector2(0.32, 0.0)
	_style_tab_inactive.border_width_left = 3
	_style_tab_inactive.border_width_right = 3
	_style_tab_inactive.border_color = Color("#8c0047")

	_tab_buttons = [tab_display_btn, tab_audio_btn, tab_controls_btn]
	_tab_pages = [display_page, audio_page, controls_page]


func _switch_section_tab(new_idx: int, play_sound: bool = true) -> void:
	var prev_idx: int = _current_tab_idx
	_current_tab_idx = posmod(new_idx, _tab_buttons.size())
	_waiting_for_action = ""
	_refresh_keybind_labels()

	if play_sound and typeof(GameManager) != TYPE_NIL:
		GameManager.play_ui_click()

	var tw: Tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.set_parallel(true)

	for i in range(_tab_buttons.size()):
		var btn: Button = _tab_buttons[i]
		if btn == null:
			continue
		var is_selected: bool = (i == _current_tab_idx)
		var target_w: float = TAB_WIDTH_EXPANDED if is_selected else TAB_WIDTH_COLLAPSED

		btn.text = _tab_full_titles[i] if is_selected else _tab_short_icons[i]
		btn.add_theme_color_override("font_color", Color.WHITE if is_selected else Color("#5e0034"))
		btn.add_theme_stylebox_override("normal", _style_tab_active if is_selected else _style_tab_inactive)
		btn.add_theme_stylebox_override("hover", _style_tab_active)
		btn.add_theme_stylebox_override("pressed", _style_tab_active)

		tw.tween_property(
			btn, "custom_minimum_size:x", target_w, 0.24
		).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	var slide_dir: float = 1.0 if _current_tab_idx >= prev_idx else -1.0
	for i in range(_tab_pages.size()):
		var page: Control = _tab_pages[i]
		if page == null:
			continue
		if i == _current_tab_idx:
			page.show()
			page.modulate.a = 0.0
			page.pivot_offset = page.size / 2.0
			page.scale = Vector2(0.96, 0.96)
			page.position.x = 45.0 * slide_dir
			tw.tween_property(page, "position:x", 0.0, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.tween_property(page, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.tween_property(page, "modulate:a", 1.0, 0.15)
		else:
			page.hide()


func _connect_all_signals() -> void:
	if back_btn:
		back_btn.pressed.connect(close_settings)
	if prev_tab_btn:
		prev_tab_btn.pressed.connect(func(): _switch_section_tab(_current_tab_idx - 1))
	if next_tab_btn:
		next_tab_btn.pressed.connect(func(): _switch_section_tab(_current_tab_idx + 1))

	if tab_display_btn:
		tab_display_btn.pressed.connect(func(): _switch_section_tab(0))
	if tab_audio_btn:
		tab_audio_btn.pressed.connect(func(): _switch_section_tab(1))
	if tab_controls_btn:
		tab_controls_btn.pressed.connect(func(): _switch_section_tab(2))

	# --- หมวด DISPLAY ---
	if res_option:
		res_option.item_selected.connect(_on_resolution_selected)
	if screen_prev_btn:
		screen_prev_btn.pressed.connect(func(): _set_screen_mode(not _is_fullscreen))
	if screen_next_btn:
		screen_next_btn.pressed.connect(func(): _set_screen_mode(not _is_fullscreen))
	if fps_prev_btn:
		fps_prev_btn.pressed.connect(func(): _step_fps(-1))
	if fps_next_btn:
		fps_next_btn.pressed.connect(func(): _step_fps(1))

	if vsync_on_check:
		vsync_on_check.pressed.connect(func(): _set_vsync(true))
	if vsync_off_check:
		vsync_off_check.pressed.connect(func(): _set_vsync(false))

	if fx_low_check:
		fx_low_check.pressed.connect(func(): _set_special_effect(false))
	if fx_high_check:
		fx_high_check.pressed.connect(func(): _set_special_effect(true))

	# --- หมวด AUDIO ---
	if master_slider:
		master_slider.value_changed.connect(_on_master_volume_changed)
	if master_minus_btn:
		master_minus_btn.pressed.connect(func(): master_slider.value = clampf(master_slider.value - 5.0, 0.0, 100.0))
	if master_plus_btn:
		master_plus_btn.pressed.connect(func(): master_slider.value = clampf(master_slider.value + 5.0, 0.0, 100.0))

	if music_slider:
		music_slider.value_changed.connect(_on_music_volume_changed)
	if music_minus_btn:
		music_minus_btn.pressed.connect(func(): music_slider.value = clampf(music_slider.value - 5.0, 0.0, 100.0))
	if music_plus_btn:
		music_plus_btn.pressed.connect(func(): music_slider.value = clampf(music_slider.value + 5.0, 0.0, 100.0))

	if sfx_slider:
		sfx_slider.value_changed.connect(_on_sfx_volume_changed)
		sfx_slider.drag_ended.connect(func(_changed: bool):
			if typeof(GameManager) != TYPE_NIL:
				GameManager.play_ui_hover()
		)
	if sfx_minus_btn:
		sfx_minus_btn.pressed.connect(func(): sfx_slider.value = clampf(sfx_slider.value - 5.0, 0.0, 100.0))
	if sfx_plus_btn:
		sfx_plus_btn.pressed.connect(func(): sfx_slider.value = clampf(sfx_slider.value + 5.0, 0.0, 100.0))

	if offset_minus_btn:
		offset_minus_btn.pressed.connect(func(): _set_audio_offset(_offset_ms - 5))
	if offset_plus_btn:
		offset_plus_btn.pressed.connect(func(): _set_audio_offset(_offset_ms + 5))

	if bgm_on_check:
		bgm_on_check.pressed.connect(func(): _set_bgm_enabled(true))
	if bgm_off_check:
		bgm_off_check.pressed.connect(func(): _set_bgm_enabled(false))

	# --- หมวด CONTROLS & RESET ---
	if left_key_btn:
		left_key_btn.pressed.connect(func(): _start_rebinding("lane_left", left_key_btn))
	if right_key_btn:
		right_key_btn.pressed.connect(func(): _start_rebinding("lane_right", right_key_btn))
	if pause_key_btn:
		pause_key_btn.pressed.connect(func(): _start_rebinding("pause_game", pause_key_btn))
	if reset_default_btn:
		reset_default_btn.pressed.connect(reset_to_defaults)


func _attach_button_hover_effects() -> void:
	for node in find_children("*", "BaseButton", true, false):
		var btn := node as BaseButton
		btn.set_meta("ui_sfx_bound", true)
		btn.resized.connect(func(): btn.pivot_offset = btn.size / 2.0)
		btn.pivot_offset = btn.size / 2.0

		btn.mouse_entered.connect(func():
			if typeof(GameManager) != TYPE_NIL:
				GameManager.play_ui_hover()
			if not (btn in _tab_buttons):
				var tw: Tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
				tw.tween_property(btn, "scale", Vector2(1.06, 1.06), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		)
		btn.mouse_exited.connect(func():
			if not (btn in _tab_buttons):
				var tw: Tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
				tw.tween_property(btn, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		)
		btn.button_down.connect(func():
			if btn != back_btn and not (btn in _tab_buttons) and typeof(GameManager) != TYPE_NIL:
				GameManager.play_ui_click()
		)


func _on_resolution_selected(idx: int) -> void:
	var clamped: int = clampi(idx, 0, RESOLUTIONS.size() - 1)
	if not _is_fullscreen:
		DisplayServer.window_set_size(RESOLUTIONS[clamped])
	if not _is_loading_config:
		save_settings()


func _set_screen_mode(fullscreen: bool) -> void:
	_is_fullscreen = fullscreen
	if screen_mode_val:
		screen_mode_val.text = "Fullscreen" if _is_fullscreen else "Windowed"
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if _is_fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	)
	if not _is_loading_config:
		save_settings()


func _step_fps(delta_step: int) -> void:
	_fps_index = posmod(_fps_index + delta_step, FPS_VALUES.size())
	_apply_fps_index(_fps_index)
	if not _is_loading_config:
		save_settings()


func _apply_fps_index(idx: int) -> void:
	_fps_index = clampi(idx, 0, FPS_VALUES.size() - 1)
	Engine.max_fps = FPS_VALUES[_fps_index]
	if fps_val_lbl:
		fps_val_lbl.text = FPS_LABELS[_fps_index]


func _set_vsync(enabled: bool) -> void:
	_vsync_enabled = enabled
	if vsync_on_check:
		vsync_on_check.set_pressed_no_signal(enabled)
	if vsync_off_check:
		vsync_off_check.set_pressed_no_signal(not enabled)
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if enabled else DisplayServer.VSYNC_DISABLED
	)
	if not _is_loading_config:
		save_settings()


func _set_special_effect(high_fx: bool) -> void:
	_high_quality_fx = high_fx
	if fx_low_check:
		fx_low_check.set_pressed_no_signal(not high_fx)
	if fx_high_check:
		fx_high_check.set_pressed_no_signal(high_fx)

	var root_scene: Node = get_tree().current_scene
	if root_scene != null:
		var world_env: WorldEnvironment = root_scene.find_child("WorldEnvironment", true, false) as WorldEnvironment
		if world_env and world_env.environment:
			world_env.environment.fog_enabled = high_fx
	if not _is_loading_config:
		save_settings()


# ==============================================================================
# การทำงานจริงของหมวด AUDIO (Master / Music / SFX / Offset / Background Music)
# ==============================================================================
func _ensure_audio_buses_exist() -> void:
	if AudioServer.get_bus_index("Music") == -1:
		var m_idx: int = AudioServer.bus_count
		AudioServer.add_bus(m_idx)
		AudioServer.set_bus_name(m_idx, "Music")
		AudioServer.set_bus_send(m_idx, "Master")

	if AudioServer.get_bus_index("SFX") == -1:
		var s_idx: int = AudioServer.bus_count
		AudioServer.add_bus(s_idx)
		AudioServer.set_bus_name(s_idx, "SFX")
		AudioServer.set_bus_send(s_idx, "Master")


func _on_master_volume_changed(val: float) -> void:
	if master_title_lbl:
		master_title_lbl.text = "Master Volume:   %d" % int(round(val))
	_set_bus_volume_percent("Master", val)
	if not _is_loading_config:
		save_settings()


func _on_music_volume_changed(val: float) -> void:
	if music_title_lbl:
		music_title_lbl.text = "Music Volume:   %d" % int(round(val))
	_route_all_music_players_in_tree()
	if _bgm_enabled:
		_set_bus_volume_percent("Music", val)
	if not _is_loading_config:
		save_settings()


func _on_sfx_volume_changed(val: float) -> void:
	if sfx_title_lbl:
		sfx_title_lbl.text = "Interactive Sound Effect Volume:   %d" % int(round(val))
	_set_bus_volume_percent("SFX", val)
	if not _is_loading_config:
		save_settings()


func _set_audio_offset(new_offset_ms: int) -> void:
	_offset_ms = clampi(new_offset_ms, -150, 150)
	custom_audio_offset_sec = float(_offset_ms) / 1000.0
	if offset_val_lbl:
		offset_val_lbl.text = "%+d ms" % _offset_ms if _offset_ms != 0 else "0 ms"

	var root_scene: Node = get_tree().current_scene
	if root_scene != null:
		var spawner: Node = root_scene.find_child("EnemySpawner", true, false)
		if spawner != null and "audio_offset" in spawner:
			spawner.audio_offset = custom_audio_offset_sec
	if not _is_loading_config:
		save_settings()


func _set_bgm_enabled(enabled: bool) -> void:
	_bgm_enabled = enabled
	if bgm_on_check:
		bgm_on_check.set_pressed_no_signal(enabled)
	if bgm_off_check:
		bgm_off_check.set_pressed_no_signal(not enabled)

	var music_bus: int = AudioServer.get_bus_index("Music")
	if music_bus >= 0:
		if not enabled:
			AudioServer.set_bus_mute(music_bus, true)
		else:
			var vol: float = music_slider.value if music_slider else 80.0
			_set_bus_volume_percent("Music", vol)
	if not _is_loading_config:
		save_settings()


func _route_all_music_players_in_tree() -> void:
	var tree_root: Node = get_tree().root if get_tree() else null
	if tree_root == null or AudioServer.get_bus_index("Music") == -1:
		return
	if typeof(GameManager) != TYPE_NIL and GameManager.has_method("bind_ui_and_audio_buses_recursive"):
		GameManager.bind_ui_and_audio_buses_recursive(tree_root)
		return
	for node in tree_root.find_children("*", "AudioStreamPlayer", true, false):
		var p := node as AudioStreamPlayer
		if not p.name.begins_with("UISFXPlayer") and p.bus == &"Master":
			p.bus = &"Music"


func _set_bus_volume_percent(bus_name: String, pct: float) -> void:
	var idx: int = AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	if pct <= 0.0:
		AudioServer.set_bus_mute(idx, true)
	else:
		AudioServer.set_bus_mute(idx, false)
		AudioServer.set_bus_volume_db(idx, linear_to_db(pct / 100.0))


# ==============================================================================
# หมวด CONTROLS, คีย์ลัด Q / E สลับแท็บ, และปุ่ม RESET TO DEFAULT
# ==============================================================================
func _init_input_map() -> void:
	for pair in [["lane_left", key_lane_left], ["lane_right", key_lane_right], ["pause_game", key_pause]]:
		var act: String = pair[0]
		var def_k: Key = pair[1]
		if not InputMap.has_action(act):
			InputMap.add_action(act)
		if InputMap.action_get_events(act).is_empty():
			var ev := InputEventKey.new()
			ev.keycode = def_k
			ev.physical_keycode = def_k
			InputMap.action_add_event(act, ev)


func _start_rebinding(action_name: String, btn: Button) -> void:
	_refresh_keybind_labels()
	_waiting_for_action = action_name
	if btn:
		btn.text = "PRESS KEY..."


func _apply_key_binding(action_name: String, new_key: Key) -> void:
	InputMap.action_erase_events(action_name)
	var ev := InputEventKey.new()
	ev.keycode = new_key
	ev.physical_keycode = new_key
	InputMap.action_add_event(action_name, ev)

	match action_name:
		"lane_left":
			key_lane_left = new_key
		"lane_right":
			key_lane_right = new_key
		"pause_game":
			key_pause = new_key

	_refresh_keybind_labels()


func _refresh_keybind_labels() -> void:
	if left_key_btn:
		left_key_btn.text = "KEY: " + OS.get_keycode_string(key_lane_left).to_upper()
	if right_key_btn:
		right_key_btn.text = "KEY: " + OS.get_keycode_string(key_lane_right).to_upper()
	if pause_key_btn:
		pause_key_btn.text = OS.get_keycode_string(key_pause).to_upper()


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		var pressed_k: Key = event.keycode if event.keycode != KEY_NONE else event.physical_keycode

		if _waiting_for_action != "":
			get_viewport().set_input_as_handled()
			_apply_key_binding(_waiting_for_action, pressed_k)
			_waiting_for_action = ""
			if typeof(GameManager) != TYPE_NIL:
				GameManager.play_ui_click()
			save_settings()
			return

		if pressed_k == KEY_Q:
			get_viewport().set_input_as_handled()
			_switch_section_tab(_current_tab_idx - 1)
		elif pressed_k == KEY_E:
			get_viewport().set_input_as_handled()
			_switch_section_tab(_current_tab_idx + 1)


func reset_to_defaults() -> void:
	_waiting_for_action = ""
	_is_loading_config = true

	if res_option:
		res_option.select(0)
	_set_screen_mode(false)
	_apply_fps_index(0) # 60 FPS
	_set_vsync(true)
	_set_special_effect(true)

	if master_slider:
		master_slider.value = 85.0
		_on_master_volume_changed(85.0)
	if music_slider:
		music_slider.value = 80.0
		_on_music_volume_changed(80.0)
	if sfx_slider:
		sfx_slider.value = 75.0
		_on_sfx_volume_changed(75.0)

	_set_audio_offset(0)
	_set_bgm_enabled(true)

	_apply_key_binding("lane_left", KEY_F)
	_apply_key_binding("lane_right", KEY_J)
	_apply_key_binding("pause_game", KEY_ESCAPE)

	_is_loading_config = false
	save_settings()

	# แอนิเมชั่นเด้งยืนยันการรีเซ็ต
	var active_page: Control = _tab_pages[_current_tab_idx]
	if active_page:
		active_page.pivot_offset = active_page.size / 2.0
		var tw: Tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.tween_property(active_page, "scale", Vector2(1.04, 0.96), 0.06)
		tw.tween_property(active_page, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func save_settings() -> void:
	if res_option:
		_config.set_value("display", "res_index", res_option.selected)
	_config.set_value("display", "fullscreen", _is_fullscreen)
	_config.set_value("display", "fps_index", _fps_index)
	_config.set_value("display", "vsync", _vsync_enabled)
	_config.set_value("display", "high_quality", _high_quality_fx)

	if master_slider:
		_config.set_value("audio", "master_volume", master_slider.value)
	if music_slider:
		_config.set_value("audio", "music_volume", music_slider.value)
	if sfx_slider:
		_config.set_value("audio", "sfx_volume", sfx_slider.value)
	_config.set_value("audio", "offset_ms", _offset_ms)
	_config.set_value("audio", "bgm_enabled", _bgm_enabled)

	_config.set_value("controls", "lane_left", int(key_lane_left))
	_config.set_value("controls", "lane_right", int(key_lane_right))
	_config.set_value("controls", "pause_game", int(key_pause))

	_config.save(CONFIG_PATH)


func load_settings() -> void:
	_is_loading_config = true
	if _config.load(CONFIG_PATH) != OK:
		_set_screen_mode(false)
		_apply_fps_index(0)
		_set_vsync(true)
		_set_special_effect(true)
		_on_master_volume_changed(85.0)
		_on_music_volume_changed(80.0)
		_on_sfx_volume_changed(75.0)
		_set_audio_offset(0)
		_set_bgm_enabled(true)
		_is_loading_config = false
		return

	if res_option:
		var r_idx: int = clampi(int(_config.get_value("display", "res_index", 0)), 0, RESOLUTIONS.size() - 1)
		res_option.select(r_idx)
	_set_screen_mode(bool(_config.get_value("display", "fullscreen", false)))
	_apply_fps_index(int(_config.get_value("display", "fps_index", 0)))
	_set_vsync(bool(_config.get_value("display", "vsync", true)))
	_set_special_effect(bool(_config.get_value("display", "high_quality", true)))

	if master_slider:
		master_slider.value = float(_config.get_value("audio", "master_volume", 85.0))
		_on_master_volume_changed(master_slider.value)
	if music_slider:
		music_slider.value = float(_config.get_value("audio", "music_volume", 80.0))
		_on_music_volume_changed(music_slider.value)
	if sfx_slider:
		sfx_slider.value = float(_config.get_value("audio", "sfx_volume", 75.0))
		_on_sfx_volume_changed(sfx_slider.value)

	_set_audio_offset(int(_config.get_value("audio", "offset_ms", 0)))
	_set_bgm_enabled(bool(_config.get_value("audio", "bgm_enabled", true)))

	_apply_key_binding("lane_left", int(_config.get_value("controls", "lane_left", KEY_F)) as Key)
	_apply_key_binding("lane_right", int(_config.get_value("controls", "lane_right", KEY_J)) as Key)
	_apply_key_binding("pause_game", int(_config.get_value("controls", "pause_game", KEY_ESCAPE)) as Key)
	_is_loading_config = false
