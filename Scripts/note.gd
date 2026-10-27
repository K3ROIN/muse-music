extends Area3D

# ==============================================================================
# สคริปต์ตัวโน้ต (Scripts/note.gd)
# เชื่อมต่อกับ GameManager เพื่อบันทึกผล PERFECT และ MISS สำหรับแสดงในหน้า Result
# ==============================================================================

@export var scroll_speed: float = 15.0
@export var miss_z_threshold: float = -2.0

var _is_judged: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	global_position.z -= scroll_speed * delta

	# --- Check MISS เมื่อโน้ตหลุดไปด้านหลังผู้เล่น (Z < -2.0) ---
	if not _is_judged and (global_position.z < miss_z_threshold or global_position.z > 80.0):
		_is_judged = true
		print("❌ MISS!")
		if typeof(GameManager) != TYPE_NIL:
			GameManager.register_miss()
		queue_free()


func _on_body_entered(body: Node3D) -> void:
	if _is_judged:
		return
	if body.name == "Player" or body.is_in_group("player"):
		_is_judged = true
		print("✨ PERFECT!")
		if typeof(GameManager) != TYPE_NIL:
			GameManager.register_perfect()
		queue_free()
