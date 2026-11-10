extends Node3D

var theme_maps: Array = [
	{
		"season_title": "STANDARD THEME",
		"map_name": "Original World",
		"preview_scene": "res://Prefabs/preview/world_mini.tscn", 
		"bg_color": Color("8cd8f2ff"),
		"particle_color": Color("ffffff")
	},
	{
		"season_title": "STANDARD THEME",
		"map_name": "Pearly Forest",
		"preview_scene": "res://Prefabs/preview/forest_mini.tscn", # Path ของกล่องสีเขียว
		"bg_color": Color("4a6741"),                # สีบรรยากาศโทนเขียวธรรมชาติ
		"particle_color": Color("ffffff")            # ใบไม้ร่วง (ในโปรโตไทป์ใช้จุดขาวแทนก่อน)
	},
	{
		"season_title": "HALLOWEEN EVENT 🎃",
		"map_name": "Spooky Forest",
		"preview_scene": "res://Prefabs/preview/halloween.tscn", # Path ของกล่องสีส้ม
		"bg_color": Color("2e1a47"),                 # สีบรรยากาศโทนม่วงลึกลับ
		"particle_color": Color("ff7700")             # จุดสีส้มฟักทอง
	},
	{
		"season_title": "CHRISTMAS EVENT 🎄",
		"map_name": "Frozen Forest",
		"preview_scene": "res://Prefabs/preview/christmas_mini.tscn", # Path ของกล่องสีแดง
		"bg_color": Color("1a365d"),                 # สีบรรยากาศโทนน้ำเงินกลางคืน
		"particle_color": Color("ffffff")             # หิมะสีขาว
	}
]

var current_index: int = 0
var current_model: Node3D = null
var rotation_speed: float = 1.0 # ความเร็วในการหมุนกล่อง

# อ้างอิง Node จากโครงสร้างที่เราวางไว้
@onready var map_container: Node3D = $AnchorPoints/MapContainer
@onready var weather_particles: GPUParticles3D = $AnchorPoints/WeatherParticles
@onready var txt_season_title: Label = $MenuUI/Control/Header/VBoxContainer/TxtSeasonTitle
@onready var txt_map_name: Label = $MenuUI/Control/Header/VBoxContainer/TxtMapName
@onready var directional_light: DirectionalLight3D = $Environment/DirectionalLight3D

func _ready() -> void:
	current_index = GameManager.saved_map_index # ดึงค่าที่เคยเซฟไว้มาใช้
	load_theme(current_index)

func _process(delta: float) -> void:
	# หมุนกล่องสี่เหลี่ยมโชว์ไปเรื่อยๆ เพื่อเช็คว่าระบบ 3D ทำงานปกติ
	if current_model and is_instance_valid(current_model):
		current_model.rotate_y(rotation_speed * delta)

func load_theme(index: int) -> void:
	# ลบกล่องเดิมออก
	if current_model:
		current_model.queue_free()
		
	var data = theme_maps[index]
	
	# 1. อัปเดตข้อความ UI 2D
	txt_season_title.text = data["season_title"]
	txt_map_name.text = data["map_name"]
	
	# 2. โหลดกล่องสี่เหลี่ยมธีมนั้นๆ มาวางตรงกลาง
	var model_resource = load(data["preview_scene"])
	if model_resource:
		current_model = model_resource.instantiate()
		map_container.add_child(current_model)
		
		# ทำ Tween ให้กล่องเด้งดึ๋งออกมาตอนเปลี่ยนด่าน
		current_model.scale = Vector3.ZERO
		var tween = create_tween()
		tween.tween_property(current_model, "scale", Vector3(1.2, 1.2, 1.2), 0.25)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

		# 3. เปลี่ยนสีแสงไฟ และสีท้องฟ้า (Sky) ตามธีมแบบสมูทๆ
	var light_tween = create_tween()
	light_tween.tween_property(directional_light, "light_color", data["bg_color"], 0.4)
	
	var env: Environment = $Environment/WorldEnvironment.environment
	if env and env.sky:
		var sky_mat = env.sky.sky_material
		if sky_mat is ProceduralSkyMaterial:
			light_tween.parallel().tween_property(sky_mat, "sky_top_color", data["bg_color"], 0.4)
			light_tween.parallel().tween_property(sky_mat, "sky_horizon_color", data["bg_color"] * 0.7, 0.4)
			# เพิ่ม 2 บรรทัดนี้เพื่อให้สีพื้นดินด้านล่างเปลี่ยนตามและเนียนกลืนไปกับท้องฟ้า
			light_tween.parallel().tween_property(sky_mat, "ground_bottom_color", data["bg_color"], 0.4)
			light_tween.parallel().tween_property(sky_mat, "ground_horizon_color", data["bg_color"] * 0.7, 0.4)


	# 4. ปรับสีเอฟเฟกต์ Particle ตามธีม (เปิดใช้งานหลังจากสร้าง ParticleProcessMaterial แล้ว)
	if weather_particles and weather_particles.process_material is ParticleProcessMaterial:
		weather_particles.process_material.color = data["particle_color"]

func _on_btn_prev_pressed() -> void:
	current_index = (current_index - 1 + theme_maps.size()) % theme_maps.size()
	load_theme(current_index)

func _on_btn_next_pressed() -> void:
	current_index = (current_index + 1) % theme_maps.size()
	load_theme(current_index)

func _on_btn_ok_pressed() -> void:
	GameManager.saved_map_index = current_index # บันทึกด่านปัจจุบันไว้ก่อนไป
	print("เข้าเล่นด่าน: ", theme_maps[current_index]["map_name"])
	# (ในอนาคต) get_tree().change_scene_to_file(...)
	#get_tree().change_scene_to_file("res://world.tscn")
