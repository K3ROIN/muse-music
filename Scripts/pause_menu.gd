extends Control

@onready var options_panel = $OptionsPanel

func _ready():
	hide()
	if options_panel:
		options_panel.hide()
	process_mode = Node.PROCESS_MODE_ALWAYS

func _unhandled_input(event):
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.physical_keycode == KEY_ESCAPE or event.physical_keycode == KEY_P:
			toggle_pause()

func toggle_pause():
	var current_pause_state = get_tree().paused
	get_tree().paused = !current_pause_state
	
	if get_tree().paused:
		show()
		if options_panel:
			options_panel.hide() # ซ่อนหน้า Option ไว้ก่อนทุกครั้งที่เปิดเมนู Pause ใหม่
		print("⏸️ GAME PAUSED!")
	else:
		hide()
		print("▶️ GAME RESUMED!")

func _on_resume_button_pressed() -> void:
	toggle_pause()

func _on_options_button_pressed() -> void:
	if options_panel:
		options_panel.show()

func _on_close_button_pressed() -> void:
	if options_panel:
		options_panel.hide()

func _on_main_menu_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
