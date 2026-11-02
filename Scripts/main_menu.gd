extends Control

const SETTINGS_SCENE_PATH: String = "res://Scenes/settings_menu.tscn"

var _settings_instance: Control = null


func _ready() -> void:
	# ซ่อน OptionsPanel แบบเก่าใน main_menu.tscn (หากยังมีอยู่)
	if has_node("OptionsPanel"):
		$OptionsPanel.hide()

	# โหลดฉาก SettingsMenu (res://Scenes/settings_menu.tscn) มาเตรียมไว้เป็น Popup
	if ResourceLoader.exists(SETTINGS_SCENE_PATH):
		var packed: PackedScene = load(SETTINGS_SCENE_PATH)
		if packed:
			_settings_instance = packed.instantiate() as Control
			add_child(_settings_instance)
			_settings_instance.hide()


func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/song_selection.tscn")


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


func _on_quit_button_pressed() -> void:
	get_tree().quit()
