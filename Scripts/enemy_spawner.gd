extends Node3D

@export var note_scene: PackedScene 
# พิกัด 3 เลน [ซ้าย, กลาง, ขวา] ที่สลับตรงตามมือปุ่ม F และ J ของคุณ
var lane_positions = [2.0, 0.0, -2.0] 

func _ready():
	$Timer.timeout.connect(_on_timer_timeout)

func _on_timer_timeout():
	if not note_scene:
		return
		
	var new_note = note_scene.instantiate()
	get_parent().add_child(new_note)
	
	# สุ่มเลนวิ่ง 
	var random_lane = randi() % 3
	var spawn_x = lane_positions[random_lane]
	
	# ให้ไปเกิดที่ Z = 35.0 (ปลายถนนด้านหน้าที่กล้องมองเห็น)
	# ความสูง Y = 0.5 เพื่อให้ลอยเด่นขึ้นมาจากพื้นถนนชัดๆ
	new_note.global_position = Vector3(spawn_x, 0.5, 35.0)
