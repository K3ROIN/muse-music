extends CharacterBody3D

var current_lane: int = 1 # 0 = ซ้าย (-2.0), 1 = กลาง (0.0), 2 = ขวา (2.0)
var lane_positions = [2.0, 0.0, -2.0]
var lane_change_speed: float = 20.0

@onready var anim_player: AnimationPlayer = find_child("AnimationPlayer", true, false)

var was_f_pressed: bool = false
var was_j_pressed: bool = false

func _ready():
	# สั่งเล่นท่าวิ่ง "sprint" ทันทีที่เริ่มเกม
	if anim_player and anim_player.has_animation("sprint"):
		anim_player.get_animation("sprint").loop_mode = Animation.LOOP_LINEAR
		anim_player.play("sprint")

func _physics_process(delta):
	var f_down = Input.is_physical_key_pressed(KEY_F)
	var j_down = Input.is_physical_key_pressed(KEY_J)
	
	var f_just = f_down and not was_f_pressed
	var j_just = j_down and not was_j_pressed
	
	# กด F+J พร้อมกัน = กลาง (1), กด F = ซ้าย (0), กด J = ขวา (2)
	if f_down and j_down and (f_just or j_just):
		current_lane = 1
	elif f_just:
		current_lane = 0
	elif j_just:
		current_lane = 2
		
	was_f_pressed = f_down
	was_j_pressed = j_down
	
	# สไลด์ตัวละครเปลี่ยนเลน
	global_position.x = lerp(global_position.x, lane_positions[current_lane], lane_change_speed * delta)
