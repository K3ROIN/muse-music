extends Control

@onready var stamina_bar: Range = $MarginContainer/TopBarHBox/StaminaVBox/StaminaBar
@onready var stamina_label = find_child("StaminaLabel", true, false)
@onready var score_label = find_child("ScoreLabel", true, false)
@onready var combo_label: Label = $CenterComboVBox/ComboLabel
@onready var judgment_label: Label = $CenterComboVBox/JudgmentLabel
@onready var damage_flash_rect: ColorRect = get_node_or_null("DamageFlashRect")

var _displayed_score: int = 0
var _score_tween: Tween
var _combo_tween: Tween
var _judgment_tween: Tween
var _stamina_tween: Tween
var _flash_tween: Tween


func _ready() -> void:
	# ตั้งค่าเริ่มต้นของ UI
	if score_label:
		score_label.text = "SCORE: 000000"
	if combo_label:
		combo_label.text = ""
		combo_label.hide()
	if judgment_label:
		judgment_label.text = ""
		judgment_label.modulate.a = 0.0
	if damage_flash_rect:
		damage_flash_rect.color = Color("f2333300")
		damage_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# เชื่อมต่อสัญญาณจาก GameManager (Autoload)
	if typeof(GameManager) != TYPE_NIL:
		if not GameManager.score_changed.is_connected(_on_score_changed):
			GameManager.score_changed.connect(_on_score_changed)
		if not GameManager.stamina_changed.is_connected(_on_stamina_changed):
			GameManager.stamina_changed.connect(_on_stamina_changed)
		if not GameManager.song_finished_for_result.is_connected(_on_song_finished):
			GameManager.song_finished_for_result.connect(_on_song_finished)

		# อัปเดตค่าหลอด Stamina เริ่มต้น
		_on_stamina_changed(GameManager.current_stamina, GameManager.max_stamina)


func _on_score_changed(new_score: int, new_combo: int, judgment: String) -> void:
	# 1. อัปเดตตัวเลขคะแนนแบบวิ่งขึ้นนุ่มนวล
	if score_label:
		if _score_tween and _score_tween.is_running():
			_score_tween.kill()
		_score_tween = create_tween()
		_score_tween.tween_method(
			func(val: int):
				_displayed_score = val
				score_label.text = "SCORE: %06d" % val,
			_displayed_score,
			new_score,
			0.18
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# 2. อัปเดตคอมโบ พร้อมอนิเมชั่นเด้ง (Scale Pop)
	if combo_label:
		if new_combo >= 2:
			combo_label.show()
			combo_label.text = "%d COMBO!" % new_combo
			combo_label.pivot_offset = combo_label.size / 2.0
			combo_label.scale = Vector2(1.35, 1.35)
			if _combo_tween and _combo_tween.is_running():
				_combo_tween.kill()
			_combo_tween = create_tween()
			_combo_tween.tween_property(combo_label, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		else:
			combo_label.hide()

	# 3. แสดงข้อความตัดสิน PERFECT / MISS
	if judgment != "" and judgment_label:
		_show_judgment_popup(judgment)

	# 4. หากเป็น MISS ให้กระพริบเตือนสีแดงและสั่นหลอด Stamina
	if judgment == "MISS":
		_play_miss_damage_effect()


func _on_stamina_changed(current_hp: float, max_hp: float) -> void:
	if stamina_bar:
		stamina_bar.max_value = max_hp
		if _stamina_tween and _stamina_tween.is_running():
			_stamina_tween.kill()
		_stamina_tween = create_tween()
		_stamina_tween.tween_property(stamina_bar, "value", current_hp, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

		# เปลี่ยนสีหลอด Stamina ตามเปอร์เซ็นต์เลือดที่เหลือ
		var ratio: float = current_hp / max(max_hp, 1.0)
		if ratio > 0.5:
			stamina_bar.modulate = Color(0.35, 0.95, 0.55) # เขียวพาสเทล (ปลอดภัย)
		elif ratio > 0.25:
			stamina_bar.modulate = Color(1.0, 0.82, 0.25)  # เหลืองส้ม (เริ่มเตือน)
		else:
			stamina_bar.modulate = Color(1.0, 0.32, 0.32)  # แดง (วิกฤต!)

	if stamina_label:
		stamina_label.text = "HP: %d / %d" % [int(ceil(current_hp)), int(max_hp)]


func _show_judgment_popup(judgment: String) -> void:
	judgment_label.text = "✨ PERFECT!" if judgment == "PERFECT" else "❌ MISS!"
	if judgment == "PERFECT":
		judgment_label.modulate = Color(1.0, 0.92, 0.3, 1.0) # สีเหลืองทอง
	else:
		judgment_label.modulate = Color(1.0, 0.35, 0.35, 1.0) # สีแดง

	judgment_label.pivot_offset = judgment_label.size / 2.0
	judgment_label.scale = Vector2(1.3, 1.3)

	if _judgment_tween and _judgment_tween.is_running():
		_judgment_tween.kill()
	_judgment_tween = create_tween()
	_judgment_tween.tween_property(judgment_label, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_judgment_tween.tween_interval(0.25)
	_judgment_tween.tween_property(judgment_label, "modulate:a", 0.0, 0.2)


func _play_miss_damage_effect() -> void:
	# กระพริบขอบจอสีแดงจางๆ เมื่อพลาดโน้ต
	if damage_flash_rect:
		if _flash_tween and _flash_tween.is_running():
			_flash_tween.kill()
		damage_flash_rect.color = Color(0.95, 0.15, 0.15, 0.28)
		_flash_tween = create_tween()
		_flash_tween.tween_property(damage_flash_rect, "color:a", 0.0, 0.25)

	# สั่นหลอด Stamina เบาๆ
	if stamina_bar:
		var orig_pos: Vector2 = stamina_bar.position
		var shake_tween: Tween = create_tween()
		shake_tween.tween_property(stamina_bar, "position:x", orig_pos.x - 6.0, 0.04)
		shake_tween.tween_property(stamina_bar, "position:x", orig_pos.x + 6.0, 0.04)
		shake_tween.tween_property(stamina_bar, "position:x", orig_pos.x, 0.04)


func _on_song_finished() -> void:
	# ซ่อน HUD เมื่อหน้าต่าง Result Screen เด้งขึ้นมา
	hide()
