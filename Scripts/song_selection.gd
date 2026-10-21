extends Control

# ฟังก์ชันทำงานเมื่อคลิกเลือก เพลงที่ 1
func _on_song_1_button_pressed() -> void:
	# สั่งโหลดฉากเล่นเกมหลัก 3D ขึ้นมาทันทีเพื่อเริ่มต้นเกม
	get_tree().change_scene_to_file("res://Scenes/world.tscn")

# ฟังก์ชันทำงานเมื่อคลิกปุ่มย้อนกลับ
func _on_back_button_pressed() -> void:
	# สั่งย้อนกลับไปหน้าจอเมนูหลักหน้าแรก
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
