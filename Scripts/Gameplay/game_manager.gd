extends Node

# ==============================================================================
# GameManager (Autoload Singleton) - res://Scripts/game_manager.gd
# ------------------------------------------------------------------------------
# จุดที่อัปเดตเพิ่ม:
# 1. ระบบเพลงคลอเมนูต่อเนื่อง (Persistent Menu BGM):
#    - เล่นเพลง BGM ("res://Audios/BGM/1-17. After the Battle.mp3") ต่อเนื่องข้ามฉาก
#      ระหว่าง Main Menu <-> Song Selection <-> Settings โดยเพลงไม่เริ่มใหม่และไม่สะดุด
#    - หยุดเพลง BGM อัตโนมัติทันทีเมื่อกดเข้าสู่ด่านเล่นเกมจริง (world.tscn)
# 2. เก็บข้อมูลเพลงที่ผู้เล่นเลือกจากหน้า Song Selection (selected_song_audio_path,
#    selected_song_midi_path) เพื่อส่งต่อให้ด่าน world.tscn
# ==============================================================================

signal score_changed(new_score: int, new_combo: int, judgment: String)
signal stamina_changed(current_hp: float, max_hp: float)
signal player_died()
signal song_finished_for_result()

const PERFECT_SCORE: int = 300
const CONFIG_PATH: String = "user://settings.cfg"

const SFX_PATHS: Dictionary = {
	"hover": "res://Audios/SFX/ui/Hover.wav",
	"click": "res://Audios/SFX/ui/Click.wav",
	"open_settings": "res://Audios/SFX/ui/Open_Settings.wav",
	"close_settings": "res://Audios/SFX/ui/Close_Settings.wav",
	"song_selected": "res://Audios/SFX/ui/Song_Selected.wav"
}

@export_group("Menu BGM Settings")
@export_file("*.mp3", "*.ogg", "*.wav") var menu_bgm_path: String = "res://Audios/BGM/1-17. After the Battle.mp3"

@export_group("Stamina / HP Settings")
@export var max_stamina: float = 100.0
@export var miss_stamina_damage: float = 15.0
@export var perfect_stamina_heal: float = 2.5

# ข้อมูลเพลงที่เลือกจากหน้า Song Selection
var selected_song_index: int = 0
var selected_song_title: String = "Talk - Demo Track"
var selected_song_audio_path: String = "res://Audios/1-18. Talk.ogg"
var selected_song_midi_path: String = "res://Audios/song1.mid"

var score: int = 0
var combo: int = 0
var max_combo: int = 0
var perfect_count: int = 0
var miss_count: int = 0
var total_notes_in_chart: int = 0

var current_stamina: float = 100.0
var is_game_over: bool = false

var saved_map_index: int = 0

var _sfx_streams: Dictionary = {}
var _sfx_players: Array[AudioStreamPlayer] = []
var _next_player_idx: int = 0
var _menu_bgm_player: AudioStreamPlayer = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_audio_buses()
	_load_saved_keybinds_and_audio_on_startup()
	_init_ui_sfx_players()
	_init_menu_bgm_player()

	get_tree().node_added.connect(_on_tree_node_added)
	if get_tree().root != null:
		bind_ui_and_audio_buses_recursive(get_tree().root)

	_check_scene_for_menu_bgm(get_tree().current_scene)


# ==============================================================================
# ระบบเพลง BGM เล่นต่อเนื่องข้ามฉาก (Main Menu <-> Song Selection)
# ==============================================================================
func _init_menu_bgm_player() -> void:
	_menu_bgm_player = AudioStreamPlayer.new()
	_menu_bgm_player.name = "MenuBGMPlayer"
	_menu_bgm_player.bus = &"Music" if AudioServer.get_bus_index("Music") != -1 else &"Master"
	_menu_bgm_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_menu_bgm_player)

	if ResourceLoader.exists(menu_bgm_path):
		var stream: AudioStream = load(menu_bgm_path)
		if stream != null:
			# เปิด Loop ให้เพลงเมนูเล่นวนซ้ำอัตโนมัติ
			if "loop" in stream:
				stream.set("loop", true)
			_menu_bgm_player.stream = stream


## เรียกเพื่อเล่นเพลง BGM เมนู (หากกำลังเล่นอยู่แล้วจะเล่นต่อทันทีโดยไม่เริ่มใหม่)
func play_menu_bgm(custom_stream: AudioStream = null) -> void:
	if _menu_bgm_player == null:
		return
	if custom_stream != null and _menu_bgm_player.stream != custom_stream:
		_menu_bgm_player.stream = custom_stream
	if _menu_bgm_player.stream != null and not _menu_bgm_player.playing:
		_menu_bgm_player.bus = &"Music" if AudioServer.get_bus_index("Music") != -1 else &"Master"
		_menu_bgm_player.play()


## เรียกเมื่อกดเข้าสู่ด่านเล่นเกมจริง (world.tscn) เพื่อหยุดเพลง BGM เมนู
func stop_menu_bgm() -> void:
	if _menu_bgm_player != null and _menu_bgm_player.playing:
		_menu_bgm_player.stop()


func _check_scene_for_menu_bgm(scene_root: Node) -> void:
	if scene_root == null:
		return
	var scene_name: String = scene_root.name.to_lower()
	var scene_file: String = scene_root.scene_file_path.to_lower()

	# ถ้าเข้าสู่ฉากเล่นเกม (world.tscn) ให้หยุดเพลงเมนูทันที
	if "world" in scene_name or "world" in scene_file:
		stop_menu_bgm()
		return

	# ถ้าอยู่ในหน้า MainMenu หรือ SongSelection ให้ดูด Stream จากโหนด AudioStreamPlayer ในฉาก (ถ้ามี)
	# มาเล่นบน _menu_bgm_player ของ GameManager แทน เพื่อให้เปลี่ยนฉากแล้วเพลงไม่ตัด
	if "mainmenu" in scene_name or "main_menu" in scene_file or "song" in scene_name or "song" in scene_file:
		for child in scene_root.find_children("*", "AudioStreamPlayer", true, false):
			var p: AudioStreamPlayer = child as AudioStreamPlayer
			if p != null and p != _menu_bgm_player and p.stream != null:
				var stream_to_use: AudioStream = p.stream
				p.stop()
				p.autoplay = false
				play_menu_bgm(stream_to_use)
				return
		play_menu_bgm()


# ==============================================================================
# โหลดปุ่มควบคุมและระดับเสียงตอนเริ่มเกม
# ==============================================================================
func _load_saved_keybinds_and_audio_on_startup() -> void:
	var cfg := ConfigFile.new()
	var err: Error = cfg.load(CONFIG_PATH)

	var left_kb1: int = int(KEY_F)
	var left_kb2: int = int(KEY_LEFT)
	var right_kb1: int = int(KEY_J)
	var right_kb2: int = int(KEY_RIGHT)
	var pause_kb1: int = int(KEY_ESCAPE)
	var pause_kb2: int = int(KEY_NONE)

	if err == OK:
		left_kb1 = int(cfg.get_value("controls_kb1", "lane_left", int(KEY_F)))
		left_kb2 = int(cfg.get_value("controls_kb2", "lane_left", int(KEY_LEFT)))
		right_kb1 = int(cfg.get_value("controls_kb1", "lane_right", int(KEY_J)))
		right_kb2 = int(cfg.get_value("controls_kb2", "lane_right", int(KEY_RIGHT)))
		pause_kb1 = int(cfg.get_value("controls_kb1", "pause_game", int(KEY_ESCAPE)))
		pause_kb2 = int(cfg.get_value("controls_kb2", "pause_game", int(KEY_NONE)))

		var m_vol: float = float(cfg.get_value("audio", "master_volume", 100.0))
		var mus_vol: float = float(cfg.get_value("audio", "music_volume", 80.0))
		var sfx_vol: float = float(cfg.get_value("audio", "sfx_volume", 100.0))
		_apply_bus_vol("Master", m_vol)
		_apply_bus_vol("Music", mus_vol)
		_apply_bus_vol("SFX", sfx_vol)

	_register_action_events("lane_left", [left_kb1, left_kb2])
	_register_action_events("lane_right", [right_kb1, right_kb2])
	_register_action_events("pause_game", [pause_kb1, pause_kb2])


func _apply_bus_vol(bus_name: String, pct: float) -> void:
	var idx: int = AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	if pct <= 0.0:
		AudioServer.set_bus_mute(idx, true)
	else:
		AudioServer.set_bus_mute(idx, false)
		AudioServer.set_bus_volume_db(idx, linear_to_db(pct / 100.0))


func _register_action_events(action_name: String, keys: Array[int]) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	InputMap.action_erase_events(action_name)

	for k in keys:
		if k != int(KEY_NONE) and k > 0:
			var ev_key := InputEventKey.new()
			ev_key.keycode = k as Key
			InputMap.action_add_event(action_name, ev_key)

			var ev_phys := InputEventKey.new()
			ev_phys.physical_keycode = k as Key
			InputMap.action_add_event(action_name, ev_phys)


func _ensure_audio_buses() -> void:
	if AudioServer.get_bus_index("Music") == -1:
		var m_idx: int = AudioServer.bus_count
		AudioServer.add_bus(m_idx)
		AudioServer.set_bus_name(m_idx, "Music")
		AudioServer.set_bus_send(m_idx, "Master")

	if AudioServer.get_bus_index("SFX") == -1:
		var idx: int = AudioServer.bus_count
		AudioServer.add_bus(idx)
		AudioServer.set_bus_name(idx, "SFX")
		AudioServer.set_bus_send(idx, "Master")


func _init_ui_sfx_players() -> void:
	for key in SFX_PATHS.keys():
		var path: String = SFX_PATHS[key]
		if ResourceLoader.exists(path):
			_sfx_streams[key] = load(path)

	for i in range(6):
		var player := AudioStreamPlayer.new()
		player.name = "UISFXPlayer_%d" % i
		player.bus = &"SFX" if AudioServer.get_bus_index("SFX") != -1 else &"Master"
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(player)
		_sfx_players.append(player)


func play_sfx(sfx_key: String, pitch_variation: float = 0.0) -> void:
	if not _sfx_streams.has(sfx_key) or _sfx_players.is_empty():
		return

	var player: AudioStreamPlayer = _sfx_players[_next_player_idx]
	_next_player_idx = (_next_player_idx + 1) % _sfx_players.size()

	player.bus = &"SFX" if AudioServer.get_bus_index("SFX") != -1 else &"Master"
	player.stream = _sfx_streams[sfx_key]
	if pitch_variation > 0.0:
		player.pitch_scale = randf_range(1.0 - pitch_variation, 1.0 + pitch_variation)
	else:
		player.pitch_scale = 1.0
	player.play()


func play_ui_hover() -> void:
	play_sfx("hover", 0.03)


func play_ui_click() -> void:
	play_sfx("click", 0.02)


func play_open_settings() -> void:
	play_sfx("open_settings")


func play_close_settings() -> void:
	play_sfx("close_settings")


func play_song_selected() -> void:
	play_sfx("song_selected")


func _on_tree_node_added(node: Node) -> void:
	if get_tree() != null and node == get_tree().current_scene:
		_check_scene_for_menu_bgm.call_deferred(node)

	if node is BaseButton:
		bind_button_sound(node as BaseButton)
	elif node is AudioStreamPlayer or node is AudioStreamPlayer3D or node is AudioStreamPlayer2D:
		_auto_assign_audio_bus(node)


func bind_ui_and_audio_buses_recursive(root: Node) -> void:
	if root == null:
		return
	if root is BaseButton:
		bind_button_sound(root as BaseButton)
	elif root is AudioStreamPlayer or root is AudioStreamPlayer3D or root is AudioStreamPlayer2D:
		_auto_assign_audio_bus(root)

	for child in root.get_children():
		bind_ui_and_audio_buses_recursive(child)


func _auto_assign_audio_bus(audio_node: Node) -> void:
	if audio_node == _menu_bgm_player:
		if AudioServer.get_bus_index("Music") != -1:
			audio_node.set("bus", &"Music")
		return

	if audio_node.get_parent() == self or audio_node.name.begins_with("UISFXPlayer"):
		if AudioServer.get_bus_index("SFX") != -1:
			audio_node.set("bus", &"SFX")
		return

	var current_bus: StringName = audio_node.get("bus")
	if current_bus == &"Master" and AudioServer.get_bus_index("Music") != -1:
		var stream: AudioStream = audio_node.get("stream")
		var path: String = stream.resource_path.to_lower() if stream != null else ""
		if "sfx" in path or "click" in path or "hover" in path:
			audio_node.set("bus", &"SFX")
		else:
			audio_node.set("bus", &"Music")


func bind_button_sound(btn: BaseButton) -> void:
	if btn == null or btn.has_meta("ui_sfx_bound"):
		return
	btn.set_meta("ui_sfx_bound", true)

	btn.mouse_entered.connect(func():
		if not btn.disabled and btn.visible:
			play_ui_hover()
	)
	btn.pressed.connect(func():
		var b_name: String = btn.name.to_lower()
		if "options" in b_name:
			play_open_settings()
		elif "saveclose" in b_name or "close" in b_name:
			play_close_settings()
		elif "song" in b_name and not ("select" in b_name):
			play_song_selected()
		else:
			play_ui_click()
	)


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

	var multiplier: int = clampi(1 + int(floor(float(combo) / 10.0)), 1, 4)
	score += PERFECT_SCORE * multiplier

	if current_stamina < max_stamina:
		current_stamina = minf(max_stamina, current_stamina + perfect_stamina_heal)
		stamina_changed.emit(current_stamina, max_stamina)

	score_changed.emit(score, combo, "PERFECT")


func register_miss() -> void:
	if is_game_over:
		return

	miss_count += 1
	combo = 0

	current_stamina = maxf(0.0, current_stamina - miss_stamina_damage)
	stamina_changed.emit(current_stamina, max_stamina)
	score_changed.emit(score, combo, "MISS")

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
