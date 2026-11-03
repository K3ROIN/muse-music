extends Control

# ==============================================================================
# Main Menu สไตล์ "JUICE KIT" + เสียงปุ่มจาก res://Audios/SFX/ui/ (res://Scripts/main_menu.gd)
# - เลื่อนเมาส์ชี้ปุ่ม: เล่นเสียง Hover.wav
# - กดปุ่ม PLAY / QUIT: เล่นเสียง Click.wav
# - กดปุ่ม OPTIONS: เล่นเสียง Open_Settings.wav
# ==============================================================================

const SETTINGS_SCENE_PATH: String = "res://Scenes/settings_menu.tscn"

@export_group("Button Colors (ปรับแต่งได้ใน Inspector)")
@export var button_normal_color: Color = Color("#f5efe2")
@export var button_text_color: Color = Color("#161224")
@export var button_shadow_color: Color = Color("#0b0812")
@export var hover_colors: Array[Color] = [
	Color("#ff5b69"), # 1. PLAY    -> แดงอมชมพู
	Color("#72ff9e"), # 2. OPTIONS -> เขียวมินต์
	Color("#5ce6ff")  # 3. QUIT    -> ฟ้าไซเบอร์
]

const SLIDE_OFFSCREEN_X: float = -520.0

var _settings_instance: Control = null
var _menu_buttons: Array[Button] = []
var _slide_items: Array[Control] = []
var _btn_styleboxes: Dictionary = {}
var _btn_hover_tweens: Dictionary = {}
var _active_slide_tween: Tween = null
var _is_animating_out: bool = false


func _ready() -> void:
	if has_node("OptionsPanel"):
		$OptionsPanel.hide()

	_setup_left_layout_and_buttons()

	if ResourceLoader.exists(SETTINGS_SCENE_PATH):
		var packed: PackedScene = load(SETTINGS_SCENE_PATH)
		if packed != null:
			_settings_instance = packed.instantiate() as Control
			add_child(_settings_instance)
			_settings_instance.hide()

	play_sequential_slide_in()


func _setup_left_layout_and_buttons() -> void:
	var title_node: Control = find_child("TitleLabel", true, false) as Control
	if title_node == null:
		title_node = find_child("RichTextLabel", true, false) as Control
	if title_node != null and title_node.custom_minimum_size == Vector2.ZERO:
		title_node.custom_minimum_size = Vector2(340, 54)

	var sub_lbl: Label = find_child("SubtitleLabel", true, false) as Label
	if sub_lbl != null and sub_lbl.custom_minimum_size == Vector2.ZERO:
		sub_lbl.custom_minimum_size = Vector2(340, 24)

	var play_btn: Button = find_child("PlayButton", true, false) as Button
	var opt_btn: Button = find_child("OptionsButton", true, false) as Button
	var quit_btn: Button = find_child("QuitButton", true, false) as Button

	_menu_buttons.clear()
	if play_btn:
		_menu_buttons.append(play_btn)
		if not play_btn.pressed.is_connected(_on_play_button_pressed):
			play_btn.pressed.connect(_on_play_button_pressed)
	if opt_btn:
		_menu_buttons.append(opt_btn)
		if not opt_btn.pressed.is_connected(_on_options_button_pressed):
			opt_btn.pressed.connect(_on_options_button_pressed)
	if quit_btn:
		_menu_buttons.append(quit_btn)
		if not quit_btn.pressed.is_connected(_on_quit_button_pressed):
			quit_btn.pressed.connect(_on_quit_button_pressed)

	for i in range(_menu_buttons.size()):
		var btn: Button = _menu_buttons[i]
		var hover_col: Color = hover_colors[i % hover_colors.size()]
		_apply_juice_kit_button_style(btn, hover_col)

	_slide_items.clear()
	if title_node:
		_wrap_in_slide_slot(title_node)
		_slide_items.append(title_node)
	if sub_lbl:
		_wrap_in_slide_slot(sub_lbl)
		_slide_items.append(sub_lbl)
	for btn in _menu_buttons:
		_wrap_in_slide_slot(btn)
		_slide_items.append(btn)


func _wrap_in_slide_slot(item: Control) -> void:
	var parent_node: Node = item.get_parent()
	if parent_node == null or not (parent_node is VBoxContainer):
		return

	var idx: int = item.get_index()
	var slot_size: Vector2 = item.custom_minimum_size
	if slot_size == Vector2.ZERO:
		slot_size = item.size if item.size != Vector2.ZERO else Vector2(310, 52)

	var slot := Control.new()
	slot.name = item.name + "Slot"
	slot.custom_minimum_size = slot_size
	slot.mouse_filter = Control.MOUSE_FILTER_PASS

	parent_node.remove_child(item)
	parent_node.add_child(slot)
	parent_node.move_child(slot, idx)

	slot.add_child(item)
	item.position = Vector2.ZERO
	item.size = slot_size


func _apply_juice_kit_button_style(btn: Button, target_hover_color: Color) -> void:
	btn.custom_minimum_size = Vector2(310, 52)
	btn.size = Vector2(310, 52)
	btn.focus_mode = Control.FOCUS_NONE
	btn.disabled = false
	btn.set_meta("ui_sfx_bound", true)

	btn.add_theme_color_override("font_color", button_text_color)
	btn.add_theme_color_override("font_hover_color", button_text_color)
	btn.add_theme_color_override("font_pressed_color", button_text_color)
	btn.add_theme_color_override("font_focus_color", button_text_color)
	btn.add_theme_color_override("font_disabled_color", button_text_color)
	btn.add_theme_font_size_override("font_size", 22)

	var sb := StyleBoxFlat.new()
	sb.bg_color = button_normal_color
	sb.skew = Vector2(0.28, 0.0)
	sb.border_width_left = 3
	sb.border_width_top = 3
	sb.border_width_right = 6
	sb.border_width_bottom = 6
	sb.border_color = button_shadow_color
	sb.shadow_color = button_shadow_color
	sb.shadow_size = 1
	sb.shadow_offset = Vector2(5, 5)
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8

	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb)
	btn.add_theme_stylebox_override("pressed", sb)
	btn.add_theme_stylebox_override("focus", sb)
	btn.add_theme_stylebox_override("disabled", sb)
	_btn_styleboxes[btn] = sb

	btn.pivot_offset = btn.custom_minimum_size / 2.0

	btn.mouse_entered.connect(func():
		if not _is_animating_out and typeof(GameManager) != TYPE_NIL:
			GameManager.play_ui_hover()
		_animate_button_hover(btn, target_hover_color, true)
	)
	btn.mouse_exited.connect(func(): _animate_button_hover(btn, button_normal_color, false))
	btn.button_down.connect(func(): _animate_button_press_punch(btn))


func play_sequential_slide_in() -> void:
	_is_animating_out = false
	if _active_slide_tween and _active_slide_tween.is_running():
		_active_slide_tween.kill()

	for tw in _btn_hover_tweens.values():
		if tw and tw.is_running():
			tw.kill()

	for item in _slide_items:
		item.modulate = Color.WHITE
		item.scale = Vector2.ONE
		item.position.x = SLIDE_OFFSCREEN_X

	for btn in _menu_buttons:
		btn.disabled = false
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
		var sb: StyleBoxFlat = _btn_styleboxes.get(btn)
		if sb:
			sb.bg_color = button_normal_color
			sb.shadow_offset = Vector2(5, 5)

	_active_slide_tween = create_tween()

	for i in range(_slide_items.size()):
		var item: Control = _slide_items[i]
		var delay_sec: float = float(i) * 0.06
		_active_slide_tween.parallel().tween_property(
			item, "position:x", 0.0, 0.26
		).set_delay(delay_sec).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func play_sequential_slide_out(on_complete: Callable) -> void:
	if _is_animating_out:
		return
	_is_animating_out = true

	if _active_slide_tween and _active_slide_tween.is_running():
		_active_slide_tween.kill()

	for tw in _btn_hover_tweens.values():
		if tw and tw.is_running():
			tw.kill()

	for btn in _menu_buttons:
		btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var sb: StyleBoxFlat = _btn_styleboxes.get(btn)
		if sb:
			sb.bg_color = button_normal_color
			sb.shadow_offset = Vector2(5, 5)

	_active_slide_tween = create_tween()

	var count: int = _slide_items.size()
	for i in range(count):
		var item: Control = _slide_items[i]
		item.modulate = Color.WHITE
		var delay_sec: float = float(i) * 0.05
		_active_slide_tween.parallel().tween_property(
			item, "position:x", SLIDE_OFFSCREEN_X, 0.22
		).set_delay(delay_sec).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)

	_active_slide_tween.chain().tween_callback(func():
		_is_animating_out = false
		on_complete.call()
	)


func _animate_button_hover(btn: Button, target_col: Color, is_hovered: bool) -> void:
	if _is_animating_out:
		return
	if _btn_hover_tweens.has(btn) and _btn_hover_tweens[btn] != null and _btn_hover_tweens[btn].is_running():
		_btn_hover_tweens[btn].kill()

	var sb: StyleBoxFlat = _btn_styleboxes.get(btn)
	var target_scale: Vector2 = Vector2(1.05, 1.05) if is_hovered else Vector2.ONE
	var target_x_offset: float = 14.0 if is_hovered else 0.0
	var target_shadow: Vector2 = Vector2(8, 8) if is_hovered else Vector2(5, 5)

	var tw: Tween = create_tween()
	tw.set_parallel(true)
	tw.tween_property(btn, "scale", target_scale, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(btn, "position:x", target_x_offset, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if sb != null:
		tw.tween_property(sb, "bg_color", target_col, 0.12)
		tw.tween_property(sb, "shadow_offset", target_shadow, 0.14)

	_btn_hover_tweens[btn] = tw


func _animate_button_press_punch(btn: Button) -> void:
	if _is_animating_out:
		return
	btn.pivot_offset = btn.size / 2.0
	var tw: Tween = create_tween()
	tw.tween_property(btn, "scale", Vector2(1.14, 0.86), 0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(btn, "scale", Vector2(0.96, 1.05), 0.06).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(btn, "scale", Vector2(1.05, 1.05), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_play_button_pressed() -> void:
	if _is_animating_out:
		return
	if typeof(GameManager) != TYPE_NIL:
		GameManager.play_ui_click()
	play_sequential_slide_out(func():
		get_tree().change_scene_to_file("res://Scenes/song_selection.tscn")
	)


func _on_options_button_pressed() -> void:
	if _is_animating_out:
		return
	if typeof(GameManager) != TYPE_NIL:
		GameManager.play_open_settings()
	await get_tree().create_timer(0.08).timeout
	if _settings_instance != null:
		if _settings_instance.has_method("open_settings"):
			_settings_instance.call("open_settings")
		else:
			_settings_instance.show()
	elif has_node("OptionsPanel"):
		$OptionsPanel.show()


func _on_close_options_button_pressed() -> void:
	if typeof(GameManager) != TYPE_NIL:
		GameManager.play_close_settings()
	if _settings_instance != null:
		_settings_instance.hide()
	if has_node("OptionsPanel"):
		$OptionsPanel.hide()


func _on_quit_button_pressed() -> void:
	if _is_animating_out:
		return
	if typeof(GameManager) != TYPE_NIL:
		GameManager.play_ui_click()
	play_sequential_slide_out(func():
		get_tree().quit()
	)
