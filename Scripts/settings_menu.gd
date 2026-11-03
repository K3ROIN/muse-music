extends Control

# ==============================================================================
# Tabbed Juicy Settings Menu + เสียงปุ่มจาก res://Audios/SFX/ui/ (res://Scripts/settings_menu.gd)
# - เปิดหน้า Settings: เล่นเสียง Open_Settings.wav
# - ปิดหน้า Settings (Save & Close): เล่นเสียง Close_Settings.wav
# - ชี้ปุ่ม / สลับแท็บ / คลิกปุ่ม: เล่นเสียง Hover.wav และ Click.wav
# ==============================================================================

const CONFIG_PATH: String = "user://settings.cfg"

static var key_lane_left: Key = KEY_F
static var key_lane_right: Key = KEY_J
static var key_pause: Key = KEY_ESCAPE
static var custom_audio_offset_sec: float = 0.0

var _config := ConfigFile.new()

@onready var main_vbox: VBoxContainer = find_child("MainVBox", true, false) as VBoxContainer
@onready var settings_tabs: TabContainer = find_child("SettingsTabs", true, false) as TabContainer

# แท็บที่ 1: Display
@onready var windowed_btn: Button = find_child("WindowedPresetBtn", true, false) as Button
@onready var fullscreen_btn: Button = find_child("FullscreenPresetBtn", true, false) as Button
@onready var hq_checkbox: CheckBox = find_child("HQCheckBox", true, false) as CheckBox
@onready var vsync_checkbtn: CheckButton = find_child("VsyncCheckButton", true, false) as CheckButton
@onready var fps_option: OptionButton = find_child("FPSOption", true, false) as OptionButton

# แท็บที่ 2: Audio
@onready var offset_spinbox: SpinBox = find_child("OffsetSpinBox", true, false) as SpinBox
@onready var master_prog_bar: ProgressBar = find_child("MasterProgressBar", true, false) as ProgressBar
@onready var music_slider: HSlider = find_child("MusicSlider", true, false) as HSlider
@onready var music_val_lbl: Label = find_child("MusicValueLabel", true, false) as Label
@onready var sfx_slider: HSlider = find_child("SFXSlider", true, false) as HSlider
@onready var sfx_val_lbl: Label = find_child("SFXValueLabel", true, false) as Label

# แท็บที่ 3: Controls
@onready var left_key_btn: Button = find_child("LeftKeyButton", true, false) as Button
@onready var right_key_btn: Button = find_child("RightKeyButton", true, false) as Button
@onready var pause_key_btn: Button = find_child("PauseKeyButton", true, false) as Button

# แถบปุ่มด้านล่าง
@onready var reset_default_btn: Button = find_child("ResetDefaultButton", true, false) as Button
@onready var save_close_btn: Button = find_child("SaveCloseButton", true, false) as Button

var _waiting_for_action: String = ""
var _is_fullscreen: bool = false
var _is_loading_config: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_init_input_map()
	_refresh_keybind_labels()
	_connect_all_signals()
	_attach_juicy_feel_and_sounds()
	load_settings()


func open_settings() -> void:
	_waiting_for_action = ""
	show()
	if main_vbox:
		main_vbox.pivot_offset = main_vbox.size / 2.0
		main_vbox.scale = Vector2(0.88, 0.88)
		main_vbox.modulate.a = 0.0
		var tw: Tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.set_parallel(true)
		tw.tween_property(main_vbox, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(main_vbox, "modulate:a", 1.0, 0.16)


func close_settings() -> void:
	_waiting_for_action = ""
	save_settings()
	if typeof(GameManager) != TYPE_NIL:
		GameManager.play_close_settings()

	if main_vbox:
		main_vbox.pivot_offset = main_vbox.size / 2.0
		var tw: Tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.set_parallel(true)
		tw.tween_property(main_vbox, "scale", Vector2(0.90, 0.90), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tw.tween_property(main_vbox, "modulate:a", 0.0, 0.14)
		tw.chain().tween_callback(func():
			if get_tree().current_scene == self:
				get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
			else:
				hide()
		)
	else:
		hide()


func _attach_juicy_feel_and_sounds() -> void:
	if settings_tabs:
		var tab_bar: TabBar = settings_tabs.get_tab_bar()
		if tab_bar:
			tab_bar.tab_hovered.connect(func(_idx: int):
				if typeof(GameManager) != TYPE_NIL:
					GameManager.play_ui_hover()
			)

	for node in find_children("*", "BaseButton", true, false):
		var btn := node as BaseButton
		btn.set_meta("ui_sfx_bound", true)
		btn.resized.connect(func(): btn.pivot_offset = btn.size / 2.0)
		btn.pivot_offset = btn.size / 2.0

		btn.mouse_entered.connect(func():
			if typeof(GameManager) != TYPE_NIL:
				GameManager.play_ui_hover()
			var tw: Tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			tw.tween_property(btn, "scale", Vector2(1.04, 1.04), 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		)
		btn.mouse_exited.connect(func():
			var tw: Tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			tw.tween_property(btn, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		)
		btn.button_down.connect(func():
			if btn != save_close_btn and typeof(GameManager) != TYPE_NIL:
				GameManager.play_ui_click()
			btn.pivot_offset = btn.size / 2.0
			var tw: Tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			tw.tween_property(btn, "scale", Vector2(1.10, 0.88), 0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.tween_property(btn, "scale", Vector2(0.97, 1.04), 0.06)
			tw.tween_property(btn, "scale", Vector2(1.04, 1.04), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		)


func _on_tab_changed(tab_idx: int) -> void:
	_waiting_for_action = ""
	_refresh_keybind_labels()
	if visible and typeof(GameManager) != TYPE_NIL:
		GameManager.play_ui_click()

	if settings_tabs == null:
		return
	var active_page: Control = settings_tabs.get_tab_control(tab_idx)
	if active_page == null:
		return

	active_page.pivot_offset = active_page.size / 2.0
	active_page.scale = Vector2(0.96, 0.96)
	active_page.modulate.a = 0.0
	var tw: Tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.set_parallel(true)
	tw.tween_property(active_page, "scale", Vector2.ONE, 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(active_page, "modulate:a", 1.0, 0.14)


func _connect_all_signals() -> void:
	if settings_tabs:
		settings_tabs.tab_changed.connect(_on_tab_changed)

	if windowed_btn:
		windowed_btn.pressed.connect(func(): _set_fullscreen_mode(false))
	if fullscreen_btn:
		fullscreen_btn.pressed.connect(func(): _set_fullscreen_mode(true))
	if hq_checkbox:
		hq_checkbox.toggled.connect(_on_high_quality_toggled)
	if vsync_checkbtn:
		vsync_checkbtn.toggled.connect(_on_vsync_toggled)
	if fps_option:
		fps_option.item_selected.connect(_on_fps_selected)

	if offset_spinbox:
		offset_spinbox.value_changed.connect(_on_audio_offset_changed)
	if music_slider:
		music_slider.value_changed.connect(_on_music_volume_changed)
	if sfx_slider:
		sfx_slider.value_changed.connect(_on_sfx_volume_changed)

	if left_key_btn:
		left_key_btn.pressed.connect(func(): _start_rebinding("lane_left", left_key_btn))
	if right_key_btn:
		right_key_btn.pressed.connect(func(): _start_rebinding("lane_right", right_key_btn))
	if pause_key_btn:
		pause_key_btn.pressed.connect(func(): _start_rebinding("pause_game", pause_key_btn))

	if reset_default_btn:
		reset_default_btn.pressed.connect(reset_to_defaults)
	if save_close_btn:
		save_close_btn.pressed.connect(close_settings)


func _set_fullscreen_mode(enable_fs: bool) -> void:
	_is_fullscreen = enable_fs
	if enable_fs:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	_update_window_mode_button_highlights()
	if not _is_loading_config:
		save_settings()


func _update_window_mode_button_highlights() -> void:
	if windowed_btn:
		windowed_btn.modulate = Color(0.24, 0.96, 1.0) if not _is_fullscreen else Color.WHITE
	if fullscreen_btn:
		fullscreen_btn.modulate = Color(0.24, 0.96, 1.0) if _is_fullscreen else Color.WHITE


func _on_high_quality_toggled(enabled: bool) -> void:
	var root_scene: Node = get_tree().current_scene
	if root_scene != null:
		var world_env: WorldEnvironment = root_scene.find_child("WorldEnvironment", true, false) as WorldEnvironment
		if world_env and world_env.environment:
			world_env.environment.fog_enabled = enabled
	if not _is_loading_config:
		save_settings()


func _on_vsync_toggled(enabled: bool) -> void:
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if enabled else DisplayServer.VSYNC_DISABLED
	)
	if not _is_loading_config:
		save_settings()


func _on_fps_selected(index: int) -> void:
	if fps_option == null:
		return
	var target_fps: int = fps_option.get_item_id(index)
	Engine.max_fps = target_fps
	if not _is_loading_config:
		if typeof(GameManager) != TYPE_NIL:
			GameManager.play_ui_click()
		save_settings()


func _on_audio_offset_changed(val_ms: float) -> void:
	custom_audio_offset_sec = val_ms / 1000.0
	var root_scene: Node = get_tree().current_scene
	if root_scene != null:
		var spawner: Node = root_scene.find_child("EnemySpawner", true, false)
		if spawner != null and "audio_offset" in spawner:
			spawner.audio_offset = custom_audio_offset_sec
	if not _is_loading_config:
		save_settings()


func _on_music_volume_changed(val: float) -> void:
	if music_val_lbl:
		music_val_lbl.text = "%d%%" % int(round(val))
	if master_prog_bar:
		var tw: Tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.tween_property(master_prog_bar, "value", val, 0.10)
	_set_bus_volume_percent("Master", val)
	if not _is_loading_config:
		save_settings()


func _on_sfx_volume_changed(val: float) -> void:
	if sfx_val_lbl:
		sfx_val_lbl.text = "%d%%" % int(round(val))
	_set_bus_volume_percent("SFX", val)
	if not _is_loading_config:
		save_settings()


func _set_bus_volume_percent(bus_name: String, pct: float) -> void:
	var idx: int = AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	if pct <= 0.0:
		AudioServer.set_bus_mute(idx, true)
	else:
		AudioServer.set_bus_mute(idx, false)
		AudioServer.set_bus_volume_db(idx, linear_to_db(pct / 100.0))


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
		btn.text = "[ Press Any Key... ]"
		btn.modulate = Color(0.24, 0.96, 1.0)


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
		left_key_btn.text = "Key: " + OS.get_keycode_string(key_lane_left).to_upper()
		left_key_btn.modulate = Color.WHITE
	if right_key_btn:
		right_key_btn.text = "Key: " + OS.get_keycode_string(key_lane_right).to_upper()
		right_key_btn.modulate = Color.WHITE
	if pause_key_btn:
		pause_key_btn.text = "Key: " + OS.get_keycode_string(key_pause).to_upper()
		pause_key_btn.modulate = Color.WHITE


func _input(event: InputEvent) -> void:
	if _waiting_for_action == "" or not visible:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		get_viewport().set_input_as_handled()
		var pressed_k: Key = event.keycode if event.keycode != KEY_NONE else event.physical_keycode
		_apply_key_binding(_waiting_for_action, pressed_k)
		_waiting_for_action = ""
		if typeof(GameManager) != TYPE_NIL:
			GameManager.play_ui_click()
		save_settings()


func reset_to_defaults() -> void:
	_waiting_for_action = ""
	_is_loading_config = true

	_set_fullscreen_mode(false)
	if hq_checkbox:
		hq_checkbox.button_pressed = true
	if vsync_checkbtn:
		vsync_checkbtn.button_pressed = true
	if fps_option:
		fps_option.select(0)
		Engine.max_fps = 0

	if offset_spinbox:
		offset_spinbox.value = 0.0
	if music_slider:
		music_slider.value = 80.0
		_on_music_volume_changed(80.0)
	if sfx_slider:
		sfx_slider.value = 75.0
		_on_sfx_volume_changed(75.0)

	_apply_key_binding("lane_left", KEY_F)
	_apply_key_binding("lane_right", KEY_J)
	_apply_key_binding("pause_game", KEY_ESCAPE)

	_is_loading_config = false
	save_settings()

	if main_vbox:
		main_vbox.pivot_offset = main_vbox.size / 2.0
		var tw: Tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.tween_property(main_vbox, "scale", Vector2(1.03, 0.97), 0.06)
		tw.tween_property(main_vbox, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func save_settings() -> void:
	_config.set_value("display", "fullscreen", _is_fullscreen)
	if hq_checkbox:
		_config.set_value("display", "high_quality", hq_checkbox.button_pressed)
	if vsync_checkbtn:
		_config.set_value("display", "vsync", vsync_checkbtn.button_pressed)
	if fps_option:
		_config.set_value("display", "fps_index", fps_option.selected)

	if offset_spinbox:
		_config.set_value("audio", "offset_ms", offset_spinbox.value)
	if music_slider:
		_config.set_value("audio", "music_volume", music_slider.value)
	if sfx_slider:
		_config.set_value("audio", "sfx_volume", sfx_slider.value)

	_config.set_value("controls", "lane_left", int(key_lane_left))
	_config.set_value("controls", "lane_right", int(key_lane_right))
	_config.set_value("controls", "pause_game", int(key_pause))

	_config.save(CONFIG_PATH)


func load_settings() -> void:
	_is_loading_config = true
	if _config.load(CONFIG_PATH) != OK:
		_update_window_mode_button_highlights()
		_on_music_volume_changed(80.0)
		_on_sfx_volume_changed(75.0)
		_is_loading_config = false
		return

	_is_fullscreen = bool(_config.get_value("display", "fullscreen", false))
	_set_fullscreen_mode(_is_fullscreen)

	if hq_checkbox:
		hq_checkbox.button_pressed = bool(_config.get_value("display", "high_quality", true))
	if vsync_checkbtn:
		vsync_checkbtn.button_pressed = bool(_config.get_value("display", "vsync", true))
	if fps_option:
		var idx: int = clampi(int(_config.get_value("display", "fps_index", 0)), 0, fps_option.item_count - 1)
		fps_option.select(idx)
		_on_fps_selected(idx)

	if offset_spinbox:
		offset_spinbox.value = float(_config.get_value("audio", "offset_ms", 0.0))
	if music_slider:
		music_slider.value = float(_config.get_value("audio", "music_volume", 80.0))
		_on_music_volume_changed(music_slider.value)
	if sfx_slider:
		sfx_slider.value = float(_config.get_value("audio", "sfx_volume", 75.0))
		_on_sfx_volume_changed(sfx_slider.value)

	_apply_key_binding("lane_left", int(_config.get_value("controls", "lane_left", KEY_F)) as Key)
	_apply_key_binding("lane_right", int(_config.get_value("controls", "lane_right", KEY_J)) as Key)
	_apply_key_binding("pause_game", int(_config.get_value("controls", "pause_game", KEY_ESCAPE)) as Key)
	_is_loading_config = false
