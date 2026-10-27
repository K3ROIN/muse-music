extends Node

# ==============================================================================
# GameManager (Autoload Singleton)
# จัดการคะแนน, คอมโบ, หลอดเลือด/Stamina (HP), ความแม่นยำ (Accuracy) และเกรดหน้า Result
# ==============================================================================

signal score_changed(new_score: int, new_combo: int, judgment: String)
signal stamina_changed(current_hp: float, max_hp: float)
signal player_died()
signal song_finished_for_result()

const PERFECT_SCORE: int = 300

@export_group("Stamina / HP Settings")
@export var max_stamina: float = 100.0
## เลือดที่ลดลงต่อการพลาดโน้ต (MISS) 1 ตัว (เช่น 15 หน่วย = พลาดติดกัน 7 ตัวเลือดหมด)
@export var miss_stamina_damage: float = 15.0
## เลือดที่ฟื้นฟูเมื่อเก็บโน้ตได้ PERFECT 1 ตัว
@export var perfect_stamina_heal: float = 2.5

var score: int = 0
var combo: int = 0
var max_combo: int = 0
var perfect_count: int = 0
var miss_count: int = 0
var total_notes_in_chart: int = 0

var current_stamina: float = 100.0
var is_game_over: bool = false


func reset_stats() -> void:
	score = 0
	combo = 0
	max_combo = 0
	perfect_count = 0
	miss_count = 0
	total_notes_in_chart = 0
	current_stamina = max_stamina
	is_game_over = false
	score_changed.emit(score, combo, "")
	stamina_changed.emit(current_stamina, max_stamina)


func register_perfect() -> void:
	if is_game_over:
		return

	perfect_count += 1
	combo += 1
	if combo > max_combo:
		max_combo = combo

	# โบนัสตัวคูณคอมโบ (เพิ่มขึ้นทุกๆ 10 คอมโบ สูงสุด 4x)
	var multiplier: int = clampi(1 + int(floor(float(combo) / 10.0)), 1, 4)
	score += PERFECT_SCORE * multiplier

	# ฟื้นฟู Stamina เล็กน้อยเมื่อกดแม่นยำต่อเนื่อง
	if current_stamina < max_stamina:
		current_stamina = minf(max_stamina, current_stamina + perfect_stamina_heal)
		stamina_changed.emit(current_stamina, max_stamina)

	score_changed.emit(score, combo, "PERFECT")


func register_miss() -> void:
	if is_game_over:
		return

	miss_count += 1
	combo = 0

	# ลด Stamina เมื่อพลาดโน้ต
	current_stamina = maxf(0.0, current_stamina - miss_stamina_damage)
	stamina_changed.emit(current_stamina, max_stamina)
	score_changed.emit(score, combo, "MISS")

	# ถ้าพลาดโน้ตสะสมจน Stamina หมด (0) ให้จบเกมทันที (Stage Failed)
	if current_stamina <= 0.0:
		is_game_over = true
		print("💀 STAMINA หมด! STAGE FAILED!")
		player_died.emit()
		song_finished_for_result.emit()


func get_total_judged_notes() -> int:
	return perfect_count + miss_count


func get_accuracy_percent() -> float:
	var judged: int = get_total_judged_notes()
	if judged <= 0:
		return 0.0
	return (float(perfect_count) / float(judged)) * 100.0


func get_rank() -> String:
	if is_game_over:
		return "F"
	var acc: float = get_accuracy_percent()
	if acc >= 95.0 and miss_count == 0:
		return "S+"
	elif acc >= 90.0:
		return "S"
	elif acc >= 80.0:
		return "A"
	elif acc >= 70.0:
		return "B"
	elif acc >= 50.0:
		return "C"
	return "F"
