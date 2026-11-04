extends Node

signal score_changed(new_score: int, new_combo: int, judgment: String)
signal stamina_changed(current_hp: float, max_hp: float)
signal player_died()
signal song_finished_for_result()

const PERFECT_SCORE: int = 300

const SFX_PATHS: Dictionary = {
	"hover": "res://Audios/SFX/ui/Hover.wav",
	"click": "res://Audios/SFX/ui/Click.wav",
	"open_settings": "res://Audios/SFX/ui/Open_Settings.wav",
	"close_settings": "res://Audios/SFX/ui/Close_Settings.wav",
	"song_selected": "res://Audios/SFX/ui/Song_Selected.wav"
}

@export_group("Stamina / HP Settings")
@export var max_stamina: float = 100.0
@export var miss_stamina_damage: float = 15.0
@export var perfect_stamina_heal: float = 2.5

var score: int = 0
var combo: int = 0
var max_combo: int = 0
var perfect_count: int = 0
var miss_count: int = 0
var total_notes_in_chart: int = 0

var current_stamina: float = 100.0
var is_game_over: bool = false

var _sfx_streams: Dictionary = {}
var _sfx_players: Array[AudioStreamPlayer] = []
var _next_player_idx: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_audio_buses()
	_init_ui_sfx_players()

	get_tree().node_added.connect(_on_tree_node_added)
	if get_tree().root:
		bind_ui_and_audio_buses_recursive(get_tree().root)


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
