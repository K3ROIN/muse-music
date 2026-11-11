extends Control

const CONFIG_PATH: String = "user://settings.cfg"

static var key_lane_left: Key = KEY_F
static var key_lane_right: Key = KEY_J
static var key_pause: Key = KEY_ESCAPE
static var custom_audio_offset_sec: float = 0.0

@export_group("Default Settings (ปรับใน Inspector ได้)")
@export_enum("Night:0", "Light:1", "Ocean:2", "Candy:3", "Dusk:4") var default_theme: int = 3
@export var default_master_volume: float = 100.0
@export var default_music_volume: float = 80.0
@export var default_sfx_volume: float = 100.0
@export var default_resolution_index: int = 1
@export var default_fullscreen: bool = false
@export var default_vsync: bool = true

@export_group("Controls Action Names (แก้ไขชื่อ Action ใน Inspector ได้)")
@export var row_1_action: String = "lane_left"
@export var row_2_action: String = "lane_right"
@export var row_3_action: String = "pause_game"

@export_group("5 Theme Palettes (Card BG, Row BG, Border, Text, Muted, Accent)")
@export var night_palette: Array[Color] = [
	Color(0.075, 0.086, 0.122, 1.0),
	Color(0.106, 0.122, 0.173, 1.0),
	Color(0.165, 0.188, 0.259, 1.0),
	Color(0.941, 0.957, 1.000, 1.0),
	Color(0.545, 0.584, 0.690, 1.0),
	Color(0.310, 0.431, 0.969, 1.0)
]
@export var light_palette: Array[Color] = [
	Color(1.000, 1.000, 1.000, 1.0),
	Color(0.965, 0.973, 0.984, 1.0),
	Color(0.886, 0.906, 0.941, 1.0),
	Color(0.102, 0.125, 0.173, 1.0),
	Color(0.392, 0.455, 0.545, 1.0),
	Color(0.310, 0.431, 0.969, 1.0)
]
@export var ocean_palette: Array[Color] = [
	Color(0.063, 0.165, 0.263, 1.0),
	Color(0.090, 0.227, 0.349, 1.0),
	Color(0.149, 0.322, 0.478, 1.0),
	Color(0.941, 0.973, 1.000, 1.0),
	Color(0.561, 0.702, 0.831, 1.0),
	Color(0.176, 0.831, 0.749, 1.0)
]
@export var candy_palette: Array[Color] = [
	Color(0.992, 0.957, 0.973, 1.0),
	Color(1.000, 1.000, 1.000, 1.0),
	Color(0.941, 0.851, 0.894, 1.0),
	Color(0.141, 0.098, 0.125, 1.0),
	Color(0.490, 0.396, 0.451, 1.0),
	Color(0.957, 0.318, 0.549, 1.0)
]
@export var dusk_palette: Array[Color] = [
	Color(0.137, 0.098, 0.204, 1.0),
	Color(0.180, 0.129, 0.267, 1.0),
	Color(0.263, 0.192, 0.388, 1.0),
	Color(0.973, 0.941, 1.000, 1.0),
	Color(0.651, 0.584, 0.741, 1.0),
	Color(0.976, 0.451, 0.086, 1.0)
]

var _config := ConfigFile.new()

@onready var main_card: PanelContainer = find_child("MainCard", true, false) as PanelContainer
@onready var tab_strip_panel: PanelContainer = find_child("TabStripPanel", true, false) as PanelContainer
@onready var title_label: Label = find_child("TitleLabel", true, false) as Label
@onready var subtitle_label: Label = find_child("SubtitleLabel", true, false) as Label

@onready var tab_audio_btn: Button = find_child("TabAudioBtn", true, false) as Button
@onready var tab_graphics_btn: Button = find_child("TabGraphicsBtn", true, false) as Button
@onready var tab_controls_btn: Button = find_child("TabControlsBtn", true, false) as Button
@onready var tab_appearance_btn: Button = find_child("TabAppearanceBtn", true, false) as Button

@onready var audio_page: Control = find_child("AudioPage", true, false) as Control
@onready var graphics_page: Control = find_child("GraphicsPage", true, false) as Control
@onready var controls_page: Control = find_child("ControlsPage", true, false) as Control
@onready var appearance_page: Control = find_child("AppearancePage", true, false) as Control

@onready var master_slider: HSlider = find_child("MasterSlider", true, false) as HSlider
@onready var master_val_label: Label = find_child("MasterValLabel", true, false) as Label
@onready var music_slider: HSlider = find_child("MusicSlider", true, false) as HSlider
@onready var music_val_label: Label = find_child("MusicValLabel", true, false) as Label
@onready var sfx_slider: HSlider = find_child("SFXSlider", true, false) as HSlider
@onready var sfx_val_label: Label = find_child("SFXValLabel", true, false) as Label

@onready var res_option: OptionButton = find_child("ResolutionOption", true, false) as OptionButton
@onready var fullscreen_check: CheckButton = find_child("FullscreenCheck", true, false) as CheckButton
@onready var vsync_check: CheckButton = find_child("VsyncCheck", true, false) as CheckButton

@onready var control_row_1: HBoxContainer = find_child("ControlRow1", true, false) as HBoxContainer
@onready var control_row_2: HBoxContainer = find_child("ControlRow2", true, false) as HBoxContainer
@onready var control_row_3: HBoxContainer = find_child("ControlRow3", true, false) as HBoxContainer

@onready var theme_option: OptionButton = find_child("ThemeOption", true, false) as OptionButton
@onready var theme_night_btn: Button = find_child("ThemeNightBtn", true, false) as Button
@onready var theme_light_btn: Button = find_child("ThemeLightBtn", true, false) as Button
@onready var theme_ocean_btn: Button = find_child("ThemeOceanBtn", true, false) as Button
@onready var theme_candy_btn: Button = find_child("ThemeCandyBtn", true, false) as Button
@onready var theme_dusk_btn: Button = find_child("ThemeDuskBtn", true, false) as Button

@onready var defaults_btn: Button = find_child("DefaultsBtn", true, false) as Button
@onready var status_label: Label = find_child("StatusLabel", true, false) as Label
@onready var close_btn: Button = find_child("CloseBtn", true, false) as Button
@onready var save_btn: Button = find_child("SaveBtn", true, false) as Button

@onready var conflict_overlay: ColorRect = find_child("ConflictOverlay", true, false) as ColorRect
@onready var conflict_card: PanelContainer = find_child("ConflictCard", true, false) as PanelContainer
@onready var conflict_title: Label = find_child("ConflictTitle", true, false) as Label
@onready var conflict_message: Label = find_child("ConflictMessage", true, false) as Label
@onready var conflict_cancel_btn: Button = find_child("ConflictCancelBtn", true, false) as Button
@onready var conflict_swap_btn: Button = find_child("ConflictSwapBtn", true, false) as Button
@onready var conflict_replace_btn: Button = find_child("ConflictReplaceBtn", true, false) as Button

var _tab_buttons: Array[Button] = []
var _tab_pages: Array[Control] = []
var _current_theme_idx: int = 3
var _is_loading: bool = false

var _bindings: Dictionary = {}
var _waiting_action: String = ""
var _waiting_slot: String = ""

var _pending_conflict_action: String = ""
var _pending_conflict_slot: String = ""
var _pending_conflict_key: int = 0
var _existing_owner_action: String = ""
var _existing_owner_slot: String = ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_audio_buses_exist()
	_setup_tabs_list()
	_setup_control_rows_data()
	_connect_all_signals()
	load_settings()
	_switch_tab(0)
	_set_status_text("")


var _card_tween: Tween
var _is_closing: bool = false


func open_settings() -> void:
	_is_closing = false
	_cancel_waiting_input()
	_route_all_music_players_in_tree()
	show()
	_switch_tab(0)
	_set_status_text("")
	
	if main_card != null:
		# ยกเลิกแอนิเมชันเก่าหากกำลังทำงานค้างอยู่
		if _card_tween != null and _card_tween.is_valid():
			_card_tween.kill()
			
		main_card.pivot_offset = main_card.size / 2.0
		main_card.scale = Vector2(0.94, 0.94)
		main_card.modulate.a = 0.0
		
		_card_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		_card_tween.set_parallel(true)
		_card_tween.tween_property(main_card, "scale", Vector2.ONE, 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_card_tween.tween_property(main_card, "modulate:a", 1.0, 0.14)


func close_settings() -> void:
	# ป้องกันผู้เล่นกดปุ่มปิดซ้ำรัวๆ ระหว่างที่หน้าต่างกำลังเล่นแอนิเมชันปิด
	if _is_closing:
		return
	_is_closing = true
	
	_cancel_waiting_input()
	save_settings()
	if typeof(GameManager) != TYPE_NIL:
		GameManager.play_close_settings()

	# เล่นแอนิเมชันย่อตัวและค่อยๆ จางหายก่อนปิดจริง
	if main_card != null:
		if _card_tween != null and _card_tween.is_valid():
			_card_tween.kill()
			
		main_card.pivot_offset = main_card.size / 2.0
		_card_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		_card_tween.set_parallel(true)
		_card_tween.tween_property(main_card, "scale", Vector2(0.94, 0.94), 0.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		_card_tween.tween_property(main_card, "modulate:a", 0.0, 0.14)
		
		# รอจนกว่าแอนิเมชันจะเล่นจบก่อนทำคำสั่งถัดไป
		await _card_tween.finished

	# ป้องกันกรณีผู้เล่นกดเปิดหน้าต่างขึ้นมาใหม่ระหว่างรอ await
	if not _is_closing:
		return
	_is_closing = false

	if get_tree().current_scene == self:
		get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
	else:
		hide()


func _setup_tabs_list() -> void:
	_tab_buttons = [tab_audio_btn, tab_graphics_btn, tab_controls_btn, tab_appearance_btn]
	_tab_pages = [audio_page, graphics_page, controls_page, appearance_page]


var _tab_tween: Tween

func _switch_tab(tab_idx: int) -> void:
	_cancel_waiting_input()
	
	if _tab_tween != null and _tab_tween.is_valid():
		_tab_tween.kill()
		
	for i in range(_tab_buttons.size()):
		var btn: Button = _tab_buttons[i]
		if btn != null:
			btn.set_pressed_no_signal(i == tab_idx)
			
		var page: Control = _tab_pages[i]
		if page != null:
			var is_selected := (i == tab_idx)
			page.visible = is_selected
			
			if is_selected:
				page.modulate.a = 0.0
				_tab_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
				_tab_tween.tween_property(page, "modulate:a", 1.0, 0.16)


func _on_tab_audio_pressed() -> void:
	_switch_tab(0)


func _on_tab_graphics_pressed() -> void:
	_switch_tab(1)


func _on_tab_controls_pressed() -> void:
	_switch_tab(2)


func _on_tab_appearance_pressed() -> void:
	_switch_tab(3)


func apply_theme_preset(preset_idx: int, mark_unsaved: bool = true) -> void:
	_current_theme_idx = clampi(preset_idx, 0, 4)
	if theme_option != null and theme_option.selected != _current_theme_idx:
		theme_option.select(_current_theme_idx)

	var pal: Array[Color] = candy_palette
	match _current_theme_idx:
		0:
			pal = night_palette
		1:
			pal = light_palette
		2:
			pal = ocean_palette
		3:
			pal = candy_palette
		4:
			pal = dusk_palette

	if pal.size() < 6:
		return

	var col_card_bg: Color = pal[0]
	var col_row_bg: Color = pal[1]
	var col_border: Color = pal[2]
	var col_text: Color = pal[3]
	var col_muted: Color = pal[4]
	var col_accent: Color = pal[5]

	var modal_sb := StyleBoxFlat.new()
	modal_sb.bg_color = col_card_bg
	modal_sb.border_color = col_border
	modal_sb.set_border_width_all(1)
	modal_sb.set_corner_radius_all(16)
	modal_sb.content_margin_left = 32
	modal_sb.content_margin_top = 28
	modal_sb.content_margin_right = 32
	modal_sb.content_margin_bottom = 24
	modal_sb.shadow_color = Color(0, 0, 0, 0.32)
	modal_sb.shadow_size = 24
	if main_card != null:
		main_card.add_theme_stylebox_override("panel", modal_sb)
	if conflict_card != null:
		conflict_card.add_theme_stylebox_override("panel", modal_sb)

	var strip_sb := StyleBoxFlat.new()
	strip_sb.bg_color = col_row_bg.darkened(0.04) if col_card_bg.get_luminance() > 0.5 else col_card_bg.darkened(0.18)
	strip_sb.border_color = col_border
	strip_sb.set_border_width_all(1)
	strip_sb.set_corner_radius_all(10)
	strip_sb.content_margin_left = 6
	strip_sb.content_margin_top = 5
	strip_sb.content_margin_right = 6
	strip_sb.content_margin_bottom = 5
	if tab_strip_panel != null:
		tab_strip_panel.add_theme_stylebox_override("panel", strip_sb)

	var tab_act_sb := StyleBoxFlat.new()
	tab_act_sb.bg_color = col_accent
	tab_act_sb.set_corner_radius_all(8)
	tab_act_sb.content_margin_left = 18
	tab_act_sb.content_margin_top = 6
	tab_act_sb.content_margin_right = 18
	tab_act_sb.content_margin_bottom = 6

	var tab_inact_sb := StyleBoxFlat.new()
	tab_inact_sb.bg_color = Color(0, 0, 0, 0)
	tab_inact_sb.set_corner_radius_all(8)
	tab_inact_sb.content_margin_left = 18
	tab_inact_sb.content_margin_top = 6
	tab_inact_sb.content_margin_right = 18
	tab_inact_sb.content_margin_bottom = 6

	var active_tab_text_col: Color = Color(0.05, 0.10, 0.15, 1.0) if _current_theme_idx == 2 else Color.WHITE
	for t_btn in _tab_buttons:
		if t_btn == null:
			continue
		t_btn.add_theme_stylebox_override("normal", tab_inact_sb)
		t_btn.add_theme_stylebox_override("hover", tab_inact_sb)
		t_btn.add_theme_stylebox_override("pressed", tab_act_sb)
		t_btn.add_theme_color_override("font_color", col_muted)
		t_btn.add_theme_color_override("font_hover_color", col_text)
		t_btn.add_theme_color_override("font_pressed_color", active_tab_text_col)
		t_btn.add_theme_color_override("font_hover_pressed_color", active_tab_text_col)

	var row_sb := StyleBoxFlat.new()
	row_sb.bg_color = col_row_bg
	row_sb.border_color = col_border
	row_sb.set_border_width_all(1)
	row_sb.set_corner_radius_all(10)
	row_sb.content_margin_left = 20
	row_sb.content_margin_top = 12
	row_sb.content_margin_right = 20
	row_sb.content_margin_bottom = 12

	for row_name in ["MasterRow", "MusicRow", "SFXRow", "ResolutionRow", "FullscreenRow", "VsyncRow", "HintCard", "ThemeSelectorRow", "QuickThemeRow"]:
		var r_node: PanelContainer = find_child(row_name, true, false) as PanelContainer
		if r_node != null:
			r_node.add_theme_stylebox_override("panel", row_sb)

	var track_sb := StyleBoxFlat.new()
	track_sb.bg_color = col_border
	track_sb.set_corner_radius_all(4)
	track_sb.content_margin_top = 3
	track_sb.content_margin_bottom = 3

	var fill_sb := StyleBoxFlat.new()
	fill_sb.bg_color = col_accent
	fill_sb.set_corner_radius_all(4)
	fill_sb.content_margin_top = 3
	fill_sb.content_margin_bottom = 3

	for sl in [master_slider, music_slider, sfx_slider]:
		if sl != null:
			sl.add_theme_stylebox_override("slider", track_sb)
			sl.add_theme_stylebox_override("grabber_area", fill_sb)
			sl.add_theme_stylebox_override("grabber_area_highlight", fill_sb)

	var sec_sb := StyleBoxFlat.new()
	sec_sb.bg_color = col_row_bg
	sec_sb.border_color = col_border
	sec_sb.set_border_width_all(1)
	sec_sb.set_corner_radius_all(8)
	sec_sb.content_margin_left = 16
	sec_sb.content_margin_top = 8
	sec_sb.content_margin_right = 16
	sec_sb.content_margin_bottom = 8

	var sec_hover_sb := sec_sb.duplicate() as StyleBoxFlat
	sec_hover_sb.border_color = col_accent

	var pri_sb := StyleBoxFlat.new()
	pri_sb.bg_color = col_accent
	pri_sb.set_corner_radius_all(8)
	pri_sb.content_margin_left = 22
	pri_sb.content_margin_top = 8
	pri_sb.content_margin_right = 22
	pri_sb.content_margin_bottom = 8

	for btn_node in find_children("*", "Button", true, false):
		var b: Button = btn_node as Button
		if b == null or b in _tab_buttons:
			continue
		if b == save_btn or b == conflict_replace_btn:
			b.add_theme_stylebox_override("normal", pri_sb)
			b.add_theme_stylebox_override("hover", pri_sb)
			b.add_theme_stylebox_override("pressed", pri_sb)
			b.add_theme_color_override("font_color", active_tab_text_col)
			b.add_theme_color_override("font_hover_color", active_tab_text_col)
		else:
			b.add_theme_stylebox_override("normal", sec_sb)
			b.add_theme_stylebox_override("hover", sec_hover_sb)
			b.add_theme_stylebox_override("pressed", sec_hover_sb)
			b.add_theme_color_override("font_color", col_text)
			b.add_theme_color_override("font_hover_color", col_accent)

	for opt_node in [res_option, theme_option]:
		if opt_node != null:
			opt_node.add_theme_stylebox_override("normal", sec_sb)
			opt_node.add_theme_stylebox_override("hover", sec_hover_sb)
			opt_node.add_theme_stylebox_override("pressed", sec_hover_sb)
			opt_node.add_theme_color_override("font_color", col_text)
			opt_node.add_theme_color_override("font_hover_color", col_accent)

	for lbl_node in find_children("*", "Label", true, false):
		var l: Label = lbl_node as Label
		if l == null:
			continue
		if l in [master_val_label, music_val_label, sfx_val_label, status_label]:
			l.add_theme_color_override("font_color", col_accent)
		elif l == subtitle_label or l.name == "Desc" or l.name == "HintLabel" or l.name.begins_with("Col"):
			l.add_theme_color_override("font_color", col_muted)
		else:
			l.add_theme_color_override("font_color", col_text)

	if mark_unsaved and not _is_loading:
		_mark_unsaved_changes()


# ==============================================================================
# 3. ระบบตาราง Controls (ซิงก์ InputMap + บันทึกไฟล์ทันทีที่ตั้งปุ่มเสร็จ)
# ==============================================================================
func _setup_control_rows_data() -> void:
	_bindings.clear()
	_register_control_row(row_1_action, control_row_1, int(KEY_F), int(KEY_LEFT), "L Stick ←")
	_register_control_row(row_2_action, control_row_2, int(KEY_J), int(KEY_RIGHT), "L Stick →")
	_register_control_row(row_3_action, control_row_3, int(KEY_ESCAPE), int(KEY_NONE), "Start")
	_sync_bindings_to_input_map()
	_refresh_control_buttons_ui()


func _register_control_row(action_name: String, row_node: HBoxContainer, def_kb1: int, def_kb2: int, def_joy: String) -> void:
	if row_node == null:
		return
	var act_lbl: Label = row_node.find_child("ActionLabel", false, false) as Label
	var btn_kb1: Button = row_node.find_child("SlotKB1", false, false) as Button
	var btn_kb2: Button = row_node.find_child("SlotKB2", false, false) as Button
	var btn_joy: Button = row_node.find_child("SlotGamepad", false, false) as Button

	var disp_name: String = act_lbl.text if act_lbl != null else action_name
	_bindings[action_name] = {
		"kb1": def_kb1,
		"kb2": def_kb2,
		"joy": def_joy,
		"default_kb1": def_kb1,
		"default_kb2": def_kb2,
		"default_joy": def_joy,
		"display_name": disp_name,
		"btn_kb1": btn_kb1,
		"btn_kb2": btn_kb2,
		"btn_joy": btn_joy
	}

	_bind_slot_button_events(action_name, "kb1", btn_kb1)
	_bind_slot_button_events(action_name, "kb2", btn_kb2)
	_bind_slot_button_events(action_name, "joy", btn_joy)


func _bind_slot_button_events(action_name: String, slot_id: String, btn: Button) -> void:
	if btn == null:
		return
	btn.pressed.connect(func(): _begin_slot_rebind(action_name, slot_id))
	btn.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_RIGHT:
			btn.accept_event()
			_clear_slot_binding(action_name, slot_id)
	)


func _begin_slot_rebind(action_name: String, slot_id: String) -> void:
	_cancel_waiting_input()
	_waiting_action = action_name
	_waiting_slot = slot_id

	if not _bindings.has(action_name):
		return
	var entry: Dictionary = _bindings[action_name]
	var btn: Button = entry.get("btn_" + slot_id) as Button
	var disp_name: String = str(entry.get("display_name", action_name))

	if btn != null:
		btn.text = "Press a button..." if slot_id == "joy" else "Press a key..."
	_set_status_text("Waiting for input for \"%s\" (Esc to cancel)." % disp_name)


func _clear_slot_binding(action_name: String, slot_id: String) -> void:
	_cancel_waiting_input()
	if not _bindings.has(action_name):
		return
	var entry: Dictionary = _bindings[action_name]
	if slot_id == "joy":
		entry["joy"] = "—"
	else:
		entry[slot_id] = int(KEY_NONE)
	_sync_bindings_to_input_map()
	_refresh_control_buttons_ui()
	save_settings()
	_mark_unsaved_changes()


func _cancel_waiting_input() -> void:
	_waiting_action = ""
	_waiting_slot = ""
	_refresh_control_buttons_ui()


func _input(event: InputEvent) -> void:
	if not visible or (conflict_overlay != null and conflict_overlay.visible):
		return
	if _waiting_action == "":
		return

	if event is InputEventKey and event.pressed and not event.echo:
		get_viewport().set_input_as_handled()
		var k: int = int(event.physical_keycode) if event.physical_keycode != KEY_NONE else int(event.keycode)

		if k == int(KEY_ESCAPE) and _waiting_action != row_3_action:
			_cancel_waiting_input()
			_set_status_text("")
			return

		if _waiting_slot == "kb1" or _waiting_slot == "kb2":
			_try_assign_keyboard_key(_waiting_action, _waiting_slot, k)
			return

	if _waiting_slot == "joy" and event is InputEventJoypadButton and event.pressed:
		get_viewport().set_input_as_handled()
		var joy_name: String = _get_gamepad_button_label(event.button_index)
		var entry: Dictionary = _bindings[_waiting_action]
		entry["joy"] = joy_name
		_cancel_waiting_input()
		save_settings()
		_mark_unsaved_changes()


func _try_assign_keyboard_key(target_action: String, target_slot: String, new_key: int) -> void:
	for act_name in _bindings.keys():
		var entry: Dictionary = _bindings[act_name]
		for s_id in ["kb1", "kb2"]:
			if act_name == target_action and s_id == target_slot:
				continue
			if int(entry[s_id]) == new_key and new_key != int(KEY_NONE):
				_open_conflict_dialog(target_action, target_slot, new_key, str(act_name), s_id)
				return

	var target_entry: Dictionary = _bindings[target_action]
	target_entry[target_slot] = new_key
	_cancel_waiting_input()
	_sync_bindings_to_input_map()
	_refresh_control_buttons_ui()
	save_settings()
	_mark_unsaved_changes()


func _open_conflict_dialog(target_act: String, target_slot: String, key_code: int, owner_act: String, owner_slot: String) -> void:
	_pending_conflict_action = target_act
	_pending_conflict_slot = target_slot
	_pending_conflict_key = key_code
	_existing_owner_action = owner_act
	_existing_owner_slot = owner_slot

	var key_str: String = _format_key_name(key_code)
	var owner_entry: Dictionary = _bindings[owner_act]
	var owner_disp: String = str(owner_entry.get("display_name", owner_act))
	if conflict_message != null:
		conflict_message.text = "\"%s\" is already bound to \"%s\".\n\nSwap: \"%s\" gets the old key.\nReplace: \"%s\" loses this key." % [
			key_str, owner_disp, owner_disp, owner_disp
		]
	if conflict_overlay != null:
		conflict_overlay.show()


func _on_conflict_cancel() -> void:
	if conflict_overlay != null:
		conflict_overlay.hide()
	_cancel_waiting_input()
	_set_status_text("")


func _on_conflict_swap() -> void:
	var pending_entry: Dictionary = _bindings[_pending_conflict_action]
	var owner_entry: Dictionary = _bindings[_existing_owner_action]
	var old_key: int = int(pending_entry[_pending_conflict_slot])
	owner_entry[_existing_owner_slot] = old_key
	pending_entry[_pending_conflict_slot] = _pending_conflict_key
	if conflict_overlay != null:
		conflict_overlay.hide()
	_cancel_waiting_input()
	_sync_bindings_to_input_map()
	_refresh_control_buttons_ui()
	save_settings()
	_mark_unsaved_changes()


func _on_conflict_replace() -> void:
	var pending_entry: Dictionary = _bindings[_pending_conflict_action]
	var owner_entry: Dictionary = _bindings[_existing_owner_action]
	owner_entry[_existing_owner_slot] = int(KEY_NONE)
	pending_entry[_pending_conflict_slot] = _pending_conflict_key
	if conflict_overlay != null:
		conflict_overlay.hide()
	_cancel_waiting_input()
	_sync_bindings_to_input_map()
	_refresh_control_buttons_ui()
	save_settings()
	_mark_unsaved_changes()


func _sync_bindings_to_input_map() -> void:
	for act_name in _bindings.keys():
		var act_str: String = str(act_name)
		if not InputMap.has_action(act_str):
			InputMap.add_action(act_str)
		InputMap.action_erase_events(act_str)

		var entry: Dictionary = _bindings[act_name]
		for s_id in ["kb1", "kb2"]:
			var k: int = int(entry[s_id])
			if k != int(KEY_NONE) and k > 0:
				# เพิ่มทั้ง keycode และ physical_keycode แยกกันเพื่อให้กดติดแม้คีย์บอร์ดเปลี่ยนภาษา
				var ev_key := InputEventKey.new()
				ev_key.keycode = k as Key
				InputMap.action_add_event(act_str, ev_key)

				var ev_phys := InputEventKey.new()
				ev_phys.physical_keycode = k as Key
				InputMap.action_add_event(act_str, ev_phys)

	if _bindings.has(row_1_action):
		var e1: Dictionary = _bindings[row_1_action]
		var k1: int = int(e1["kb1"])
		key_lane_left = (k1 as Key) if (k1 != int(KEY_NONE) and k1 > 0) else KEY_NONE
	if _bindings.has(row_2_action):
		var e2: Dictionary = _bindings[row_2_action]
		var k2: int = int(e2["kb1"])
		key_lane_right = (k2 as Key) if (k2 != int(KEY_NONE) and k2 > 0) else KEY_NONE
	if _bindings.has(row_3_action):
		var e3: Dictionary = _bindings[row_3_action]
		var kp: int = int(e3["kb1"])
		if kp != int(KEY_NONE) and kp > 0:
			key_pause = kp as Key


func _refresh_control_buttons_ui() -> void:
	for act_name in _bindings.keys():
		var entry: Dictionary = _bindings[act_name]
		var b_kb1: Button = entry.get("btn_kb1") as Button
		var b_kb2: Button = entry.get("btn_kb2") as Button
		var b_joy: Button = entry.get("btn_joy") as Button
		if b_kb1 != null:
			b_kb1.text = _format_key_name(int(entry["kb1"]))
		if b_kb2 != null:
			b_kb2.text = _format_key_name(int(entry["kb2"]))
		if b_joy != null:
			b_joy.text = str(entry["joy"])


func _format_key_name(k: int) -> String:
	if k == int(KEY_NONE) or k <= 0:
		return "—"
	match k:
		KEY_LEFT:
			return "←"
		KEY_RIGHT:
			return "→"
		KEY_UP:
			return "↑"
		KEY_DOWN:
			return "↓"
		_:
			return OS.get_keycode_string(k as Key)


func _get_gamepad_button_label(btn_idx: JoyButton) -> String:
	match btn_idx:
		JOY_BUTTON_A:
			return "A / Cross"
		JOY_BUTTON_B:
			return "B / Circle"
		JOY_BUTTON_X:
			return "X / Square"
		JOY_BUTTON_Y:
			return "Y / Triangle"
		JOY_BUTTON_START:
			return "Start"
		JOY_BUTTON_LEFT_SHOULDER:
			return "LB / L1"
		JOY_BUTTON_RIGHT_SHOULDER:
			return "RB / R1"
		_:
			return "Button " + str(int(btn_idx))


# ==============================================================================
# 4. การเชื่อมสัญญาณและการทำงานของ Audio / Graphics / Defaults / Save
# ==============================================================================
func _connect_all_signals() -> void:
	if tab_audio_btn != null and not tab_audio_btn.pressed.is_connected(_on_tab_audio_pressed):
		tab_audio_btn.pressed.connect(_on_tab_audio_pressed)
	if tab_graphics_btn != null and not tab_graphics_btn.pressed.is_connected(_on_tab_graphics_pressed):
		tab_graphics_btn.pressed.connect(_on_tab_graphics_pressed)
	if tab_controls_btn != null and not tab_controls_btn.pressed.is_connected(_on_tab_controls_pressed):
		tab_controls_btn.pressed.connect(_on_tab_controls_pressed)
	if tab_appearance_btn != null and not tab_appearance_btn.pressed.is_connected(_on_tab_appearance_pressed):
		tab_appearance_btn.pressed.connect(_on_tab_appearance_pressed)

	if master_slider != null and not master_slider.value_changed.is_connected(_on_master_volume_changed):
		master_slider.value_changed.connect(_on_master_volume_changed)
	if music_slider != null and not music_slider.value_changed.is_connected(_on_music_volume_changed):
		music_slider.value_changed.connect(_on_music_volume_changed)
	if sfx_slider != null and not sfx_slider.value_changed.is_connected(_on_sfx_volume_changed):
		sfx_slider.value_changed.connect(_on_sfx_volume_changed)

	if res_option != null and not res_option.item_selected.is_connected(_on_resolution_selected):
		res_option.item_selected.connect(_on_resolution_selected)
	if fullscreen_check != null and not fullscreen_check.toggled.is_connected(_on_fullscreen_toggled):
		fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	if vsync_check != null and not vsync_check.toggled.is_connected(_on_vsync_toggled):
		vsync_check.toggled.connect(_on_vsync_toggled)

	if theme_option != null and not theme_option.item_selected.is_connected(_on_theme_option_selected):
		theme_option.item_selected.connect(_on_theme_option_selected)
	if theme_night_btn != null and not theme_night_btn.pressed.is_connected(_on_theme_night_pressed):
		theme_night_btn.pressed.connect(_on_theme_night_pressed)
	if theme_light_btn != null and not theme_light_btn.pressed.is_connected(_on_theme_light_pressed):
		theme_light_btn.pressed.connect(_on_theme_light_pressed)
	if theme_ocean_btn != null and not theme_ocean_btn.pressed.is_connected(_on_theme_ocean_pressed):
		theme_ocean_btn.pressed.connect(_on_theme_ocean_pressed)
	if theme_candy_btn != null and not theme_candy_btn.pressed.is_connected(_on_theme_candy_pressed):
		theme_candy_btn.pressed.connect(_on_theme_candy_pressed)
	if theme_dusk_btn != null and not theme_dusk_btn.pressed.is_connected(_on_theme_dusk_pressed):
		theme_dusk_btn.pressed.connect(_on_theme_dusk_pressed)

	if defaults_btn != null and not defaults_btn.pressed.is_connected(reset_to_defaults):
		defaults_btn.pressed.connect(reset_to_defaults)
	if close_btn != null and not close_btn.pressed.is_connected(close_settings):
		close_btn.pressed.connect(close_settings)
	if save_btn != null and not save_btn.pressed.is_connected(_on_save_button_pressed):
		save_btn.pressed.connect(_on_save_button_pressed)

	if conflict_cancel_btn != null and not conflict_cancel_btn.pressed.is_connected(_on_conflict_cancel):
		conflict_cancel_btn.pressed.connect(_on_conflict_cancel)
	if conflict_swap_btn != null and not conflict_swap_btn.pressed.is_connected(_on_conflict_swap):
		conflict_swap_btn.pressed.connect(_on_conflict_swap)
	if conflict_replace_btn != null and not conflict_replace_btn.pressed.is_connected(_on_conflict_replace):
		conflict_replace_btn.pressed.connect(_on_conflict_replace)


func _on_theme_option_selected(idx: int) -> void:
	apply_theme_preset(idx, true)


func _on_theme_night_pressed() -> void:
	apply_theme_preset(0, true)


func _on_theme_light_pressed() -> void:
	apply_theme_preset(1, true)


func _on_theme_ocean_pressed() -> void:
	apply_theme_preset(2, true)


func _on_theme_candy_pressed() -> void:
	apply_theme_preset(3, true)


func _on_theme_dusk_pressed() -> void:
	apply_theme_preset(4, true)


func _on_save_button_pressed() -> void:
	save_settings()
	_set_status_text("Settings saved.")


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
	if master_val_label != null:
		master_val_label.text = "%d %%" % int(round(val))
	_set_bus_volume_percent("Master", val)
	if not _is_loading:
		_mark_unsaved_changes()


func _on_music_volume_changed(val: float) -> void:
	if music_val_label != null:
		music_val_label.text = "%d %%" % int(round(val))
	_route_all_music_players_in_tree()
	_set_bus_volume_percent("Music", val)
	if not _is_loading:
		_mark_unsaved_changes()


func _on_sfx_volume_changed(val: float) -> void:
	if sfx_val_label != null:
		sfx_val_label.text = "%d %%" % int(round(val))
	_set_bus_volume_percent("SFX", val)
	if not _is_loading:
		_mark_unsaved_changes()


func _on_resolution_selected(idx: int) -> void:
	if res_option == null or idx < 0 or idx >= res_option.item_count:
		return
	var raw_txt: String = res_option.get_item_text(idx).replace("×", "x").to_lower()
	var parts: PackedStringArray = raw_txt.split("x")
	if parts.size() == 2:
		var w: int = int(parts[0].strip_edges())
		var h: int = int(parts[1].strip_edges())
		if w > 0 and h > 0 and (fullscreen_check == null or not fullscreen_check.button_pressed):
			DisplayServer.window_set_size(Vector2i(w, h))
	if not _is_loading:
		_mark_unsaved_changes()


func _on_fullscreen_toggled(enabled: bool) -> void:
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if enabled else DisplayServer.WINDOW_MODE_WINDOWED
	)
	if not _is_loading:
		_mark_unsaved_changes()


func _on_vsync_toggled(enabled: bool) -> void:
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if enabled else DisplayServer.VSYNC_DISABLED
	)
	if not _is_loading:
		_mark_unsaved_changes()


func _route_all_music_players_in_tree() -> void:
	var tree_root: Node = get_tree().root if get_tree() != null else null
	if tree_root == null or AudioServer.get_bus_index("Music") == -1:
		return
	if typeof(GameManager) != TYPE_NIL and GameManager.has_method("bind_ui_and_audio_buses_recursive"):
		GameManager.bind_ui_and_audio_buses_recursive(tree_root)
		return
	for node in tree_root.find_children("*", "AudioStreamPlayer", true, false):
		var p: AudioStreamPlayer = node as AudioStreamPlayer
		if p != null and not p.name.begins_with("UISFXPlayer") and p.bus == &"Master":
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


func _mark_unsaved_changes() -> void:
	_set_status_text("Unsaved changes.")


func _set_status_text(txt: String) -> void:
	if status_label != null:
		status_label.text = txt


# ==============================================================================
# 5. ปุ่ม Defaults และการบันทึก/โหลดไฟล์ user://settings.cfg
# ==============================================================================
func reset_to_defaults() -> void:
	_cancel_waiting_input()
	_is_loading = true

	if master_slider != null:
		master_slider.value = default_master_volume
		_on_master_volume_changed(default_master_volume)
	if music_slider != null:
		music_slider.value = default_music_volume
		_on_music_volume_changed(default_music_volume)
	if sfx_slider != null:
		sfx_slider.value = default_sfx_volume
		_on_sfx_volume_changed(default_sfx_volume)

	if res_option != null and res_option.item_count > 0:
		var r_idx: int = clampi(default_resolution_index, 0, res_option.item_count - 1)
		res_option.select(r_idx)
		_on_resolution_selected(r_idx)

	if fullscreen_check != null:
		fullscreen_check.button_pressed = default_fullscreen
		_on_fullscreen_toggled(default_fullscreen)
	if vsync_check != null:
		vsync_check.button_pressed = default_vsync
		_on_vsync_toggled(default_vsync)

	for act_name in _bindings.keys():
		var entry: Dictionary = _bindings[act_name]
		entry["kb1"] = int(entry["default_kb1"])
		entry["kb2"] = int(entry["default_kb2"])
		entry["joy"] = str(entry["default_joy"])
	_sync_bindings_to_input_map()
	_refresh_control_buttons_ui()

	apply_theme_preset(default_theme, false)
	save_settings()

	_is_loading = false
	_mark_unsaved_changes()


func save_settings() -> void:
	if master_slider != null:
		_config.set_value("audio", "master_volume", master_slider.value)
	if music_slider != null:
		_config.set_value("audio", "music_volume", music_slider.value)
	if sfx_slider != null:
		_config.set_value("audio", "sfx_volume", sfx_slider.value)

	if res_option != null:
		_config.set_value("graphics", "res_index", res_option.selected)
	if fullscreen_check != null:
		_config.set_value("graphics", "fullscreen", fullscreen_check.button_pressed)
	if vsync_check != null:
		_config.set_value("graphics", "vsync", vsync_check.button_pressed)

	_config.set_value("appearance", "theme_index", _current_theme_idx)

	for act_name in _bindings.keys():
		var entry: Dictionary = _bindings[act_name]
		_config.set_value("controls_kb1", str(act_name), int(entry["kb1"]))
		_config.set_value("controls_kb2", str(act_name), int(entry["kb2"]))
		_config.set_value("controls_joy", str(act_name), str(entry["joy"]))

	_config.save(CONFIG_PATH)


func load_settings() -> void:
	_is_loading = true
	if _config.load(CONFIG_PATH) != OK:
		reset_to_defaults()
		_set_status_text("")
		_is_loading = false
		return

	if master_slider != null:
		master_slider.value = float(_config.get_value("audio", "master_volume", default_master_volume))
		_on_master_volume_changed(master_slider.value)
	if music_slider != null:
		music_slider.value = float(_config.get_value("audio", "music_volume", default_music_volume))
		_on_music_volume_changed(music_slider.value)
	if sfx_slider != null:
		sfx_slider.value = float(_config.get_value("audio", "sfx_volume", default_sfx_volume))
		_on_sfx_volume_changed(sfx_slider.value)

	if res_option != null and res_option.item_count > 0:
		var r_idx: int = clampi(int(_config.get_value("graphics", "res_index", default_resolution_index)), 0, res_option.item_count - 1)
		res_option.select(r_idx)
		_on_resolution_selected(r_idx)

	if fullscreen_check != null:
		fullscreen_check.button_pressed = bool(_config.get_value("graphics", "fullscreen", default_fullscreen))
		_on_fullscreen_toggled(fullscreen_check.button_pressed)
	if vsync_check != null:
		vsync_check.button_pressed = bool(_config.get_value("graphics", "vsync", default_vsync))
		_on_vsync_toggled(vsync_check.button_pressed)

	for act_name in _bindings.keys():
		var entry: Dictionary = _bindings[act_name]
		entry["kb1"] = int(_config.get_value("controls_kb1", str(act_name), entry["default_kb1"]))
		entry["kb2"] = int(_config.get_value("controls_kb2", str(act_name), entry["default_kb2"]))
		entry["joy"] = str(_config.get_value("controls_joy", str(act_name), entry["default_joy"]))
	_sync_bindings_to_input_map()
	_refresh_control_buttons_ui()

	var saved_theme: int = int(_config.get_value("appearance", "theme_index", default_theme))
	apply_theme_preset(saved_theme, false)

	_is_loading = false
	_set_status_text("")
