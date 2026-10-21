extends MeshInstance3D

@export var scroll_speed: float = 5.0 # ความเร็วในการไหลของลายพื้นถนน

func _process(delta):
	# ดึง Material ของถนนมาเลื่อนตำแหน่งลายภาพ (UV) ให้ไหลไปเรื่อยๆ ไม่มีวันหมด
	var mat: StandardMaterial3D = mesh.material
	if mat:
		# ถ้าลายถนนไหลผิดทิศ ให้เปลี่ยนเครื่องหมาย - เป็น + นะครับ
		mat.uv1_offset.y += scroll_speed * delta
