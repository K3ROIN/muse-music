extends Control

const CONFIG_PATH: String = "user://settings.cfg"

static var key_lane_left: Key = KEY_F
static var key_lane_right: Key = KEY_J
static var key_pause: Key = KEY_ESCAPE

const COL_BG_SLATE := Color("#262140")
const COL_CYAN := Color("#00f0ff")
const COL_PINK := Color("#ff5577")
const COL_TEXT := Color("#e8f4ff")

var _config := ConfigFile.new()

@onready var main_card: PanelContainer = find_child("MainCard", true, false) as PanelContainer
@onready var back_btn: Button = find_child("BackButton", true, false) as Button
@onready var controls_or_reset_btn: Button = find_child("ControlsOrResetButton", true, false) as Button
@onready var settings_grid_view: Control = find_child("SettingsGridView", true, false) as Control
@onready var controls_sub_view: VBoxContainer = find_child("ControlsSubView", true, false) as VBoxContainer

@onready var fps_option: OptionButton = find_child("FPSOption", true, false) as OptionButton
@onready var vsync_toggle: CheckButton = find_child("VsyncToggle", true, false) as CheckButton
@onready var lang_option: OptionButton = find_child("LangOption", true, false) as OptionButton
@onready var fullscreen_toggle: CheckButton = find_child("FullscreenToggle", true, false) as CheckButton
@onready var hq_toggle: CheckButton = find_child("HQToggle", true, false) as CheckButton

@onready var music_slider: HSlider = find_child("MusicSlider", true, false) as HSlider
@onready var music_num_label: Label = find_child("MusicNumLabel", true, false) as Label
@onready var sfx_slider: HSlider = find_child("SFXSlider", true, false) as HSlider
@onready var sfx_num_label: Label = find_child("SFXNumLabel", true, false) as Label

var _is_in_controls_view: bool = false
var _kb_buttons: Dictionary = {}
var _joy_buttons: Dictionary = {}
var _waiting_action: String = ""
var _waiting_device: String = ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_init_input_map()
	_populate_controls_sub_view()
	_connect_ui_signals()
	load_settings()
	_show_main_settings_view()


func open_settings() -> void:
	_show_main_settings_view()
	show()
	if main_card:
		main_card.pivot_offset = main_card.size / 2.0
		main_card.scale = Vector2(0.92, 0.92)
		var tw: Tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.tween_property(main_card, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func close_settings() -> void:
	_waiting_action = ""
	save_settings()
	# หากเปิดเป็น Scene เดี่ยว (รันตรงจาก settings_menu.tscn) ให้กลับหน้า MainMenu
	if get_tree().current_scene == self:
		get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
	else:
		hide()


func _connect_ui_signals() -> void:
	if back_btn:
		back_btn.pressed.connect(_on_back_button_pressed)
	if controls_or_reset_btn:
		controls_or_reset_btn.pressed.connect(_on_bottom_left_button_pressed)

	if fps_option:
		fps_option.item_selected.connect(_on_fps_selected)
	if vsync_toggle:
		vsync_toggle.toggled.connect(func(on: bool):
			DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if on else DisplayServer.VSYNC_DISABLED)
		)
	if fullscreen_toggle:
		fullscreen_toggle.toggled.connect(func(on: bool):
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if on else DisplayServer.WINDOW_MODE_WINDOWED)
		)
	if hq_toggle:
		hq_toggle.toggled.connect(_on_high_quality_toggled)

	if music_slider:
		music_slider.value_changed.connect(func(val: float):
			if music_num_label:
				music_num_label.text = str(int(round(val)))
			_set_bus_percent("Master", val)
		)
	if sfx_slider:
		sfx_slider.value_changed.connect(func(val: float):
			if sfx_num_label:
				sfx_num_label.text = str(int(round(val)))
			_set_bus_percent("SFX", val)
		)

func _populate_controls_sub_view() -> void:
	if controls_sub_view == null or controls_sub_view.get_child_count() > 0:
		return

	var header := HBoxContainer.new()
	controls_sub_view.add_child(header)

	var h_act := _make_label("")
	h_act.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(h_act)

	var h_kb := _make_label("Keyboard/mouse", COL_CYAN)
	h_kb.custom_minimum_size = Vector2(140, 0)
	h_kb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_child(h_kb)

	var h_joy := _make_label("Joystick", COL_PINK)
	h_joy.custom_minimum_size = Vector2(120, 0)
	h_joy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_child(h_joy)

	_add_control_bind_row("Left (Lane X = 2.0)", "lane_left", key_lane_left, "LB / D-Left")
	_add_control_bind_row("Right (Lane X = -2.0)", "lane_right", key_lane_right, "RB / D-Right")
	_add_control_bind_row("Pause Menu", "pause_game", key_pause, "Start")


func _add_control_bind_row(title: String, action: String, def_key: Key, joy_text: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	controls_sub_view.add_child(row)

	var lbl := _make_label(title)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(lbl)

	var kb_btn := _make_skewed_button(OS.get_keycode_string(def_key).to_upper(), Vector2(140, 36), COL_CYAN)
	kb_btn.pressed.connect(func():
		_waiting_action = action
		_waiting_device = "kb"
		kb_btn.text = "..."
	)
	row.add_child(kb_btn)
	_kb_buttons[action] = kb_btn

	var joy_btn := _make_skewed_button(joy_text, Vector2(120, 36), COL_PINK)
	joy_btn.pressed.connect(func():
		_waiting_action = action
		_waiting_device = "joy"
		joy_btn.text = "..."
	)
	row.add_child(joy_btn)
	_joy_buttons[action] = joy_btn


func _show_main_settings_view() -> void:
	_is_in_controls_view = false
	_waiting_action = ""
	if settings_grid_view:
		settings_grid_view.show()
	if controls_sub_view:
		controls_sub_view.hide()
	if controls_or_reset_btn:
		controls_or_reset_btn.text = "Controls"

func _show_controls_sub_view() -> void:
	_is_in_controls_view = true
	_waiting_action = ""
	if settings_grid_view:
		settings_grid_view.hide()
	if controls_sub_view:
		controls_sub_view.show()
	if controls_or_reset_btn:
		controls_or_reset_btn.text = "Reset"


func _on_back_button_pressed() -> void:
	if _is_in_controls_view:
		_show_main_settings_view()
	else:
		close_settings()


func _on_bottom_left_button_pressed() -> void:
	if not _is_in_controls_view:
		_show_controls_sub_view()
	else:
		_apply_key_binding("lane_left", KEY_F)
		_apply_key_binding("lane_right", KEY_J)
		_apply_key_binding("pause_game", KEY_ESCAPE)
		save_settings()


func _input(event: InputEvent) -> void:
	if _waiting_action == "" or not visible:
		return

	if _waiting_device == "kb" and event is InputEventKey and event.pressed and not event.echo:
		get_viewport().set_input_as_handled()
		var k: Key = event.keycode if event.keycode != KEY_NONE else event.physical_keycode
		_apply_key_binding(_waiting_action, k)
		_waiting_action = ""
		save_settings()
	elif _waiting_device == "joy" and event is InputEventJoypadButton and event.pressed:
		get_viewport().set_input_as_handled()
		InputMap.action_add_event(_waiting_action, event)
		if _joy_buttons.has(_waiting_action):
			_joy_buttons[_waiting_action].text = "BTN " + str(event.button_index)
		_waiting_action = ""
		save_settings()


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

	if _kb_buttons.has(action_name):
		_kb_buttons[action_name].text = OS.get_keycode_string(new_key).to_upper()


func _on_fps_selected(idx: int) -> void:
	match idx:
		0: Engine.max_fps = 0
		1: Engine.max_fps = 60
		2: Engine.max_fps = 120


func _on_high_quality_toggled(on: bool) -> void:
	var env_node: WorldEnvironment = get_tree().current_scene.find_child("WorldEnvironment", true, false) as WorldEnvironment if get_tree().current_scene else null
	if env_node and env_node.environment:
		env_node.environment.fog_enabled = on


func _set_bus_percent(bus_name: String, pct: float) -> void:
	var idx: int = AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	if pct <= 0.0:
		AudioServer.set_bus_mute(idx, true)
	else:
		AudioServer.set_bus_mute(idx, false)
		AudioServer.set_bus_volume_db(idx, linear_to_db(pct / 100.0))


func save_settings() -> void:
	if vsync_toggle:
		_config.set_value("settings", "vsync", vsync_toggle.button_pressed)
	if fullscreen_toggle:
		_config.set_value("settings", "fullscreen", fullscreen_toggle.button_pressed)
	if hq_toggle:
		_config.set_value("settings", "high_quality", hq_toggle.button_pressed)
	if fps_option:
		_config.set_value("settings", "fps_idx", fps_option.selected)
	if music_slider:
		_config.set_value("settings", "music", music_slider.value)
	if sfx_slider:
		_config.set_value("settings", "sfx", sfx_slider.value)
	_config.set_value("controls", "lane_left", int(key_lane_left))
	_config.set_value("controls", "lane_right", int(key_lane_right))
	_config.set_value("controls", "pause_game", int(key_pause))
	_config.save(CONFIG_PATH)


func load_settings() -> void:
	if _config.load(CONFIG_PATH) != OK:
		return
	if vsync_toggle:
		vsync_toggle.button_pressed = bool(_config.get_value("settings", "vsync", true))
	if fullscreen_toggle:
		fullscreen_toggle.button_pressed = bool(_config.get_value("settings", "fullscreen", false))
	if hq_toggle:
		hq_toggle.button_pressed = bool(_config.get_value("settings", "high_quality", true))
	if fps_option:
		fps_option.select(int(_config.get_value("settings", "fps_idx", 0)))
	if music_slider:
		music_slider.value = float(_config.get_value("settings", "music", 80.0))
	if sfx_slider:
		sfx_slider.value = float(_config.get_value("settings", "sfx", 75.0))
	_apply_key_binding("lane_left", int(_config.get_value("controls", "lane_left", KEY_F)) as Key)
	_apply_key_binding("lane_right", int(_config.get_value("controls", "lane_right", KEY_J)) as Key)
	_apply_key_binding("pause_game", int(_config.get_value("controls", "pause_game", KEY_ESCAPE)) as Key)


func _make_skewed_button(txt: String, min_sz: Vector2, accent: Color) -> Button:
	var btn := Button.new()
	btn.text = txt
	btn.custom_minimum_size = min_sz
	btn.add_theme_color_override("font_color", COL_TEXT)
	btn.add_theme_color_override("font_hover_color", COL_CYAN)

	var normal := StyleBoxFlat.new()
	normal.bg_color = COL_BG_SLATE
	normal.border_color = accent
	normal.skew = Vector2(0.28, 0.0)
	normal.set_border_width_all(2)

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.21, 0.18, 0.36)
	hover.border_color = COL_CYAN

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", hover)
	return btn


func _make_label(txt: String, col: Color = COL_TEXT) -> Label:
	var lbl := Label.new()
	lbl.text = txt
	lbl.add_theme_color_override("font_color", col)
	lbl.add_theme_font_size_override("font_size", 17)
	return lbl
