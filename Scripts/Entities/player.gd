extends CharacterBody3D

# ==============================================================================
# สคริปต์ควบคุมตัวละคร (res://Scripts/player.gd)
# เชื่อมต่อกับระบบตั้งค่าปุ่มใน Settings Menu (res://Scripts/settings_menu.gd) และ InputMap
# ------------------------------------------------------------------------------
# จุดที่แก้ไข:
# 1. เลิกเช็กปุ่ม F และ J แบบตายตัว (Hardcode) เปลี่ยนมาอ่านปุ่มจาก Action "lane_left"
#    และ "lane_right" ที่ผู้เล่นตั้งค่าไว้ในหน้า Settings (เช่น เปลี่ยนเป็น D กับ K ก็ใช้ D กับ K ได้ทันที)
# 2. โหลดค่าปุ่มจากไฟล์ "user://settings.cfg" ตอนเริ่มด่านเผื่อผู้เล่นกดเข้าด่านโดยไม่ได้เปิดหน้า Settings ก่อน
# 3. รองรับทั้งปุ่มช่องที่ 1 (KEYBOARD 1), ช่องที่ 2 (KEYBOARD 2), จอยสติ๊ก (GAMEPAD)
#    และรองรับกรณีคีย์บอร์ดติดภาษาไทย (เช็กทั้ง keycode และ physical_keycode)
# ==============================================================================

const CONFIG_PATH: String = "user://settings.cfg"

@export var lanes: Array[float] = [2.0, 0.0, -2.0]
@export var current_lane: int = 1
@export var lane_change_speed: float = 15.0

var target_x: float = 0.0


func _ready() -> void:
	_ensure_saved_keybinds_loaded()

	target_x = lanes[current_lane]
	position.x = target_x

	var anim_player: AnimationPlayer = find_child("AnimationPlayer", true, false) as AnimationPlayer
	if anim_player != null and anim_player.has_animation("sprint"):
		anim_player.play("sprint")


func _process(delta: float) -> void:
	var left_pressed: bool = _is_lane_action_active("lane_left")
	var right_pressed: bool = _is_lane_action_active("lane_right")

	# กดซ้าย + ขวา พร้อมกัน (เช่น D + K) = เลนกลาง (X = 0.0)
	if left_pressed and right_pressed:
		current_lane = 1
	elif left_pressed:
		current_lane = 0 # เลนซ้าย (X = 2.0)
	elif right_pressed:
		current_lane = 2 # เลนขวา (X = -2.0)

	target_x = lanes[current_lane]
	position.x = lerp(position.x, target_x, lane_change_speed * delta)


func _is_lane_action_active(action_name: String) -> bool:
	if InputMap.has_action(action_name) and Input.is_action_pressed(action_name):
		return true

	# ตรวจสอบเพิ่มเติมจากรายการ InputEventKey ใน InputMap โดยตรง (รองรับกรณีคีย์บอร์ดค้างภาษาไทย)
	if InputMap.has_action(action_name):
		for ev in InputMap.action_get_events(action_name):
			if ev is InputEventKey:
				var kev := ev as InputEventKey
				if kev.keycode != KEY_NONE and (Input.is_key_pressed(kev.keycode) or Input.is_physical_key_pressed(kev.keycode)):
					return true
				if kev.physical_keycode != KEY_NONE and (Input.is_key_pressed(kev.physical_keycode) or Input.is_physical_key_pressed(kev.physical_keycode)):
					return true
	return false


# โหลดค่าปุ่มจาก user://settings.cfg เข้าสู่ InputMap อัตโนมัติเมื่อเริ่มฉากวิ่ง
func _ensure_saved_keybinds_loaded() -> void:
	var cfg := ConfigFile.new()
	var err: Error = cfg.load(CONFIG_PATH)

	var left_kb1: int = int(KEY_F)
	var left_kb2: int = int(KEY_LEFT)
	var right_kb1: int = int(KEY_J)
	var right_kb2: int = int(KEY_RIGHT)

	if err == OK:
		left_kb1 = int(cfg.get_value("controls_kb1", "lane_left", int(KEY_F)))
		left_kb2 = int(cfg.get_value("controls_kb2", "lane_left", int(KEY_LEFT)))
		right_kb1 = int(cfg.get_value("controls_kb1", "lane_right", int(KEY_J)))
		right_kb2 = int(cfg.get_value("controls_kb2", "lane_right", int(KEY_RIGHT)))

	_bind_action_keys("lane_left", [left_kb1, left_kb2])
	_bind_action_keys("lane_right", [right_kb1, right_kb2])


func _bind_action_keys(action_name: String, keys: Array[int]) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	InputMap.action_erase_events(action_name)

	for k in keys:
		if k != int(KEY_NONE) and k > 0:
			# เพิ่มทั้ง keycode และ physical_keycode เพื่อให้กดติดทั้งตอนคีย์บอร์ดเป็นภาษาอังกฤษและภาษาไทย
			var ev_key := InputEventKey.new()
			ev_key.keycode = k as Key
			InputMap.action_add_event(action_name, ev_key)

			var ev_phys := InputEventKey.new()
			ev_phys.physical_keycode = k as Key
			InputMap.action_add_event(action_name, ev_phys)
