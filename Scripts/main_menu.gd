extends Control

# ค้นหาโหนดที่ชื่อ OptionsPanel อัตโนมัติ ไม่ว่าจะวางซ้อนไว้ชั้นไหนก็ตาม
@onready var options_panel = find_child("OptionsPanel", true, false)

func _ready():
	if options_panel:
		options_panel.hide()
	else:
		print("⚠️ หาโหนดชื่อ OptionsPanel ไม่เจอ! เช็กตัวสะกดชื่อโหนดฝั่งซ้ายด้วยนะครับ")

func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/song_selection.tscn")

func _on_options_button_pressed() -> void:
	print("🖱️ กดปุ่ม Options แล้ว!") # เช็กในหน้าต่าง Output ด้านล่างว่าปุ่มทำงานไหม
	if options_panel:
		options_panel.show()

func _on_close_button_pressed() -> void:
	if options_panel:
		options_panel.hide()

func _on_quit_button_pressed() -> void:
	get_tree().quit()
