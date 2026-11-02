extends Control

const SETTINGS_SCENE_PATH: String = "res://Scenes/settings_menu.tscn"

var _settings_instance: Control = null

func _ready() -> void:
	# บังคับให้ Node นี้ทำงานได้ตลอดเวลาแม้เกมจะสั่ง Pause อยู่ก็ตาม
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = 100
	set_process_input(true)

	# ซ่อนเมนูและหน้าต่างอื่น ๆ ไว้ตอนเริ่มเกม
	hide()
	if has_node("OptionsPanel"):
		$OptionsPanel.hide()

	# เชื่อมต่อ Signal ของปุ่มต่าง ๆ ในหน้าเมนูอัตโนมัติ
	var resume_btn: Button = find_child("ResumeButton", true, false) as Button
	if resume_btn and not resume_btn.pressed.is_connected(_on_resume_button_pressed):
		resume_btn.pressed.connect(_on_resume_button_pressed)

	var opt_btn: Button = find_child("OptionsButton", true, false) as Button
	if opt_btn and not opt_btn.pressed.is_connected(_on_options_button_pressed):
		opt_btn.pressed.connect(_on_options_button_pressed)

	var menu_btn: Button = find_child("MainMenuButton", true, false) as Button
	if menu_btn and not menu_btn.pressed.is_connected(_on_main_menu_button_pressed):
		menu_btn.pressed.connect(_on_main_menu_button_pressed)

	var close_opt_btn: Button = find_child("CloseOptionsButton", true, false) as Button
	if close_opt_btn and not close_opt_btn.pressed.is_connected(_on_close_options_button_pressed):
		close_opt_btn.pressed.connect(_on_close_options_button_pressed)

	# โหลดหน้าเมนู Settings มารอไว้ล่วงหน้า
	if ResourceLoader.exists(SETTINGS_SCENE_PATH):
		var packed: PackedScene = load(SETTINGS_SCENE_PATH)
		if packed != null:
			_settings_instance = packed.instantiate() as Control
			add_child(_settings_instance)
			_settings_instance.hide()


func _input(event: InputEvent) -> void:
	# 1. ตรวจจับการกดปุ่ม Esc ตรง ๆ 
	var is_esc_key: bool = false
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE or event.physical_keycode == KEY_ESCAPE:
			is_esc_key = true

	# 2. ตรวจจับผ่านแอคชันใน Input Map (ที่เราตั้งค่าไว้ในขั้นตอนที่ 1 หรือปุ่มพื้นฐาน ui_cancel)
	var is_pause_action: bool = event.is_action_pressed("ui_cancel") or (
		InputMap.has_action("pause_game") and event.is_action_pressed("pause_game")
	)

	# ถ้ามีการกดปุ่ม Esc หรือปุ่ม Pause เกิดขึ้น
	if is_esc_key or is_pause_action:
		# ถ้าหน้าจอแสดงผลลัพธ์ (ResultScreen) กำลังเปิดอยู่ จะกด Pause ซ้อนไม่ได้
		var result_node: Control = get_parent().find_child("ResultScreen", false, false) as Control if get_parent() else null
		if result_node != null and result_node.visible:
			return

		# ถ้าหน้าตั้งค่า (Settings) เปิดอยู่ ให้ปิดหน้าตั้งค่าก่อนแทนการปิดเมนูหลัก
		if _settings_instance != null and _settings_instance.visible:
			if _settings_instance.has_method("close_settings"):
				_settings_instance.call("close_settings")
			else:
				_settings_instance.hide()
			get_viewport().set_input_as_handled()
			return

		if has_node("OptionsPanel") and $OptionsPanel.visible:
			$OptionsPanel.hide()
			get_viewport().set_input_as_handled()
			return

		# หากไม่มีเมนูอื่นเปิดค้างไว้ ให้สั่ง สลับสถานะหยุดเกม/เล่นเกม ทันที
		get_viewport().set_input_as_handled()
		toggle_pause()


func toggle_pause() -> void:
	var new_pause_state: bool = not get_tree().paused
	
	# ดึง Node หลักที่จะนำมาทำเอฟเฟกต์สไลด์เด้ง
	var container = $CenterContainer if has_node("CenterContainer") else null
	var bg_overlay = $ColorRect if has_node("ColorRect") else null
	
	if new_pause_state:
		# --- ขาเปิดเมนู (สไลด์เด้งคลี่ลงมาจากแกนกลาง) ---
		get_tree().paused = true 
		show()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		
		if bg_overlay:
			bg_overlay.show()
			bg_overlay.modulate.a = 0.0 # เริ่มจากโปร่งใส
		
		if container:
			container.show()
			# ตั้งจุดหมุน (Pivot) ไว้ตรงใจกลางกล่อง เพื่อให้ระเบิดหรือขยายจากจุดศูนย์กลางได้สมดุล
			container.pivot_offset = container.size / 2
			container.scale = Vector2(1.0, 0.0) # บีบแบนแนวตั้ง (เริ่มที่ความสูง 0)
			container.modulate.a = 0.0 # เริ่มจากจางหาย

		# เรียกใช้งานระบบ Tween ควบคู่กัน (Parallel) ทั้งฉากหลังและปุ่มกด
		var tween = create_tween().set_parallel(true)
		
		# ค่อย ๆ จางพื้นหลังมืดเข้ามาภายในเวลา 0.2 วินาที
		if bg_overlay:
			tween.tween_property(bg_overlay, "modulate:a", 0.6, 0.2)
			
		# คลี่เมนูปุ่มกดลงมาพร้อมแรงเด้งดึ๋ง (TRANS_BACK + EASE_OUT)
		if container:
			tween.tween_property(container, "scale", Vector2(1.0, 1.0), 0.3)\
				.set_trans(Tween.TRANS_BACK)\
				.set_ease(Tween.EASE_OUT)
			tween.tween_property(container, "modulate:a", 1.0, 0.2)
			
	else:
		# --- ขาปิดเมนู (หุบเก็บขึ้นไปแกนกลาง) ---
		var tween = create_tween().set_parallel(true)
		
		if bg_overlay:
			tween.tween_property(bg_overlay, "modulate:a", 0.0, 0.2)
			
		if container:
			# หุบเมนูกลับแบบนุ่มนวลเร่งความเร็ว (TRANS_QUAD + EASE_IN)
			tween.tween_property(container, "scale", Vector2(1.0, 0.0), 0.2)\
				.set_trans(Tween.TRANS_QUAD)\
				.set_ease(Tween.EASE_IN)
			tween.tween_property(container, "modulate:a", 0.0, 0.15)
			
		# สำคัญ: รอจนกว่าแอนิเมชันของ Tween จะขยับปิดเสร็จหมด ค่อยสั่งเคลียร์สถานะจริง
		await tween.finished
		
		get_tree().paused = false
		hide()
		if _settings_instance != null:
			_settings_instance.hide()
		if has_node("OptionsPanel"):
			$OptionsPanel.hide()


func _on_resume_button_pressed() -> void:
	if get_tree().paused:
		toggle_pause()


func _on_options_button_pressed() -> void:
	if _settings_instance != null:
		if _settings_instance.has_method("open_settings"):
			_settings_instance.call("open_settings")
		else:
			_settings_instance.show()
	elif has_node("OptionsPanel"):
		$OptionsPanel.show()


func _on_close_options_button_pressed() -> void:
	if _settings_instance != null:
		_settings_instance.hide()
	if has_node("OptionsPanel"):
		$OptionsPanel.hide()


func _on_main_menu_button_pressed() -> void:
	# ปลดล็อกสถานะหยุดเวลาก่อนสลับฉาก เพื่อไม่ให้โลกหลักค้าง
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
