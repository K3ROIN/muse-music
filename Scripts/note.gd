extends Area3D

@export var scroll_speed: float = 15.0

func _ready():
	# เชื่อมสัญญาณชน (ถ้าชนตัวละครให้ลบทิ้งทันที)
	body_entered.connect(_on_body_entered)

func _process(delta):
	# ตัวโน้ตวิ่งเข้าหาตัวละคร (ปรับตามแกนถนนหลักของคุณ)
	global_position.z -= scroll_speed * delta
	
	# ── ระบบกู้ชีพเช็ก MISS ──
	# ถ้าตัวโน้ตวิ่งเลยตัวละคร (Z=0) และทะลุผ่านหลังกล้องไปแล้ว (ค่า Z ลดลงเรื่อยๆ จนติดลบมากๆ)
	# หรือถ้ามันวิ่งหนีไปอีกฝั่ง (ค่า Z เพิ่มขึ้นเกินด่าน) 
	# โค้ดนี้จะดักลบทุกกรณีถ้ามันหลุดออกนอกระยะสายตาเกิน 15 เมตร!
	if global_position.z < -15.0 or global_position.z > 80.0:
		print("❌ MISS!")
		queue_free()

func _on_body_entered(body: Node3D):
	# เช็กชนตัวละครแบบง่ายที่สุด (เช็กจากชื่อโหนดตรงๆ)
	if body.name == "Player" or body.is_in_group("player"):
		print("✨ PERFECT!")
		queue_free() # ชนแล้วหายทันที ไม่ทะลุหลัง
