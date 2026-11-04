extends Control

func _ready() -> void:
	for child in find_children("*", "Button", true, false):
		var btn := child as Button
		btn.set_meta("ui_sfx_bound", true)
		btn.resized.connect(func(): btn.pivot_offset = btn.size / 2.0)
		btn.pivot_offset = btn.size / 2.0

		btn.mouse_entered.connect(func():
			if typeof(GameManager) != TYPE_NIL:
				GameManager.play_ui_hover()
			var tw: Tween = create_tween()
			tw.tween_property(btn, "scale", Vector2(1.05, 1.05), 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		)
		btn.mouse_exited.connect(func():
			var tw: Tween = create_tween()
			tw.tween_property(btn, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		)


func _on_song_1_button_pressed() -> void:
	if typeof(GameManager) != TYPE_NIL:
		GameManager.play_song_selected()
	get_tree().change_scene_to_file("res://Scenes/world.tscn")


func _on_back_button_pressed() -> void:
	if typeof(GameManager) != TYPE_NIL:
		GameManager.play_ui_click()
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
