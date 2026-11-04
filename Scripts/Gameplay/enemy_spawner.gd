extends Node3D

# ==============================================================================
# ระบบอ่านไฟล์ .mid ล่วงหน้าแบบ Hybrid + หยุดเพลงทันทีเมื่อ Stamina หมด (Stage Failed)
# ==============================================================================

signal chart_loaded(total_notes: int, song_duration: float)
signal note_spawned(note_node: Node3D, note_data: Dictionary)
signal realtime_midi_beat(pitch: int, track: int)

@export_group("Node References")
@export var note_scene: PackedScene = preload("res://Prefabs/note.tscn")
@export var audio_player: Node
@export var midi_player: Node

@export_group("MIDI & Track Settings")
@export_file("*.mid", "*.midi") var midi_file_path: String = "res://Audios/song1.mid"
@export var target_track_index: int = -1
@export var min_note_interval: float = 0.12

@export_group("3-Lane Runner Settings")
@export var lanes: Array[float] = [2.0, 0.0, -2.0]
@export var spawn_z: float = 35.0
@export var player_z: float = 0.0
@export var note_scroll_speed: float = 15.0
@export var audio_offset: float = 0.0
@export var result_delay_after_end: float = 2.0

@export_group("MIDI Pitch to Lane Mapping")
@export var use_custom_pitch_map: bool = false
@export var left_lane_pitch: int = 60   # C4 -> ซ้าย (F)
@export var center_lane_pitch: int = 62 # D4 -> กลาง (F+J)
@export var right_lane_pitch: int = 64  # E4 -> ขวา (J)

var note_queue: Array[Dictionary] = []
var next_note_index: int = 0
var _spawned_keys: Dictionary = {}

var lead_time: float = 0.0
var song_position: float = 0.0
var last_note_hit_time: float = 0.0
var is_running: bool = false
var _audio_started: bool = false
var _result_triggered: bool = false


func _ready() -> void:
	if has_node("Timer"):
		$Timer.stop()

	if audio_player == null and get_parent() != null:
		if get_parent().has_node("AudioStreamPlayer3D"):
			audio_player = get_parent().get_node("AudioStreamPlayer3D")
		elif get_parent().has_node("AudioStreamPlayer"):
			audio_player = get_parent().get_node("AudioStreamPlayer")

	if audio_player != null:
		if audio_player.get("playing"):
			audio_player.call("stop")
		if audio_player.has_signal("finished"):
			audio_player.connect("finished", _on_audio_finished)

	if typeof(GameManager) != TYPE_NIL:
		GameManager.reset_stats()
		if not GameManager.player_died.is_connected(_on_player_died):
			GameManager.player_died.connect(_on_player_died)

	lead_time = abs(spawn_z - player_z) / max(note_scroll_speed, 0.001)

	var parsed_ok: bool = preload_chart_with_midi_file_parser(midi_file_path)
	var sync_ok: bool = setup_godot_midi_player(midi_file_path)

	if parsed_ok or sync_ok:
		start_chart_with_preroll()
	else:
		push_warning("⚠️ ไม่พบไฟล์ .mid ที่กำหนด สลับไปใช้โหมด $Timer สุ่มโน้ตสำรอง")
		if has_node("Timer"):
			$Timer.start()


func _process(delta: float) -> void:
	if not is_running:
		return

	if not _audio_started:
		song_position += delta
		if song_position >= 0.0:
			_audio_started = true
			_begin_synced_playback()
	else:
		if audio_player != null and audio_player.get("playing"):
			song_position = (
				float(audio_player.call("get_playback_position"))
				+ AudioServer.get_time_since_last_mix()
				- AudioServer.get_output_latency()
				+ audio_offset
			)
		else:
			song_position += delta

	while next_note_index < note_queue.size():
		var note_data: Dictionary = note_queue[next_note_index]
		if song_position >= float(note_data["spawn_time"]):
			_spawn_note_once(note_data)
			next_note_index += 1
		else:
			break

	if _audio_started and midi_player != null and midi_player.has_method("get_notes_in_range"):
		var target_hit_time: float = song_position + lead_time
		var ahead_events: Array = midi_player.call("get_notes_in_range", target_hit_time - 0.04, target_hit_time + 0.04)
		for ev in ahead_events:
			if not ev.get("active", true):
				continue
			var hit_t: float = float(ev.get("time", 0.0))
			var pitch: int = int(ev.get("note", 60))
			var lane: int = map_pitch_to_lane(pitch)
			if lane != -1:
				_spawn_note_once({
					"hit_time": hit_t,
					"spawn_time": hit_t - lead_time,
					"lane": lane,
					"pitch": pitch,
					"note_name": "",
					"frequency": 440.0
				})

	if not _result_triggered and note_queue.size() > 0 and next_note_index >= note_queue.size():
		if song_position >= last_note_hit_time + result_delay_after_end:
			_trigger_result_screen()


func _on_player_died() -> void:
	# หยุดการปล่อยโน้ตและหยุดเพลงทันทีเมื่อ Stamina หมด
	is_running = false
	_result_triggered = true
	if has_node("Timer"):
		$Timer.stop()
	if audio_player != null and audio_player.has_method("stop"):
		audio_player.call("stop")
	if midi_player != null and midi_player.has_method("stop"):
		midi_player.call("stop")

	# ลบโน้ตที่ค้างอยู่ในฉากออกทั้งหมด
	for child in get_children():
		if child is Area3D:
			child.queue_free()

	# หากไม่ได้วาง ResultScreen เป็น Overlay ใน World/CanvasLayer ให้เปลี่ยนไปยังฉาก Result
	var current_scene: Node = get_tree().current_scene
	if current_scene != null and current_scene.find_child("ResultScreen", true, false) == null:
		if ResourceLoader.exists("res://Scenes/result_screen.tscn"):
			get_tree().change_scene_to_file("res://Scenes/result_screen.tscn")


func preload_chart_with_midi_file_parser(path: String) -> bool:
	note_queue.clear()
	_spawned_keys.clear()
	if not FileAccess.file_exists(path):
		return false

	var parser_script: Script = null
	for candidate_path in ["res://midi_file_parser.gd", "res://addons/gdscript-midi-parser/midi_file_parser.gd", "res://Scripts/midi_file_parser.gd"]:
		if ResourceLoader.exists(candidate_path):
			parser_script = load(candidate_path)
			break

	if parser_script == null:
		return false

	var parser = parser_script.call("load_file", path)
	if parser == null:
		return false

	var time_division: int = int(parser.header.time_division)
	if time_division <= 0:
		time_division = 480

	var tempo_changes: Array[Dictionary] = [{"tick": 0, "ms_per_tick": 500.0 / float(time_division)}]
	for track in parser.tracks:
		for meta_ev in track.meta:
			if int(meta_ev.type) == 81:
				tempo_changes.append({"tick": int(meta_ev.absolute_ticks), "ms_per_tick": float(meta_ev.ms_per_tick)})

	tempo_changes.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["tick"]) < int(b["tick"]))

	var raw_notes: Array[Dictionary] = []
	for t_idx in range(parser.tracks.size()):
		if target_track_index != -1 and t_idx != target_track_index:
			continue
		var track = parser.tracks[t_idx]
		for midi_ev in track.midi:
			if int(midi_ev.status) == 0x9 and int(midi_ev.param2) > 0:
				var abs_tick: int = int(midi_ev.absolute_ticks)
				var hit_time_sec: float = _ticks_to_seconds_with_tempo_map(abs_tick, tempo_changes)
				raw_notes.append({
					"hit_time": hit_time_sec,
					"pitch": int(midi_ev.param1),
					"note_name": str(midi_ev.note_name),
					"frequency": float(midi_ev.frequency),
					"track": t_idx
				})

	raw_notes.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["hit_time"]) < float(b["hit_time"]))

	var last_time: float = -999.0
	for n in raw_notes:
		var hit_t: float = float(n["hit_time"])
		var pitch: int = int(n["pitch"])
		var lane: int = map_pitch_to_lane(pitch)
		if lane == -1:
			continue
		if hit_t - last_time >= min_note_interval:
			note_queue.append({
				"hit_time": hit_t,
				"spawn_time": hit_t - lead_time,
				"lane": lane,
				"pitch": pitch,
				"note_name": n["note_name"],
				"frequency": n["frequency"]
			})
			last_time = hit_t

	last_note_hit_time = last_time if last_time > 0.0 else 0.0
	if typeof(GameManager) != TYPE_NIL:
		GameManager.total_notes_in_chart = note_queue.size()
	chart_loaded.emit(note_queue.size(), last_note_hit_time)
	return note_queue.size() > 0


func _ticks_to_seconds_with_tempo_map(target_tick: int, tempo_changes: Array[Dictionary]) -> float:
	var total_ms: float = 0.0
	var last_tick: int = 0
	var current_ms_per_tick: float = float(tempo_changes[0]["ms_per_tick"])
	for t_ev in tempo_changes:
		var ev_tick: int = int(t_ev["tick"])
		if ev_tick >= target_tick:
			break
		if ev_tick > last_tick:
			total_ms += float(ev_tick - last_tick) * current_ms_per_tick
			last_tick = ev_tick
		current_ms_per_tick = float(t_ev["ms_per_tick"])
	if target_tick > last_tick:
		total_ms += float(target_tick - last_tick) * current_ms_per_tick
	return total_ms / 1000.0


func setup_godot_midi_player(path: String) -> bool:
	if midi_player == null:
		return false
	if ClassDB.class_exists("MidiResource") and FileAccess.file_exists(path):
		var midi_res = ClassDB.instantiate("MidiResource")
		if midi_res != null and midi_res.has_method("load_file"):
			if midi_res.call("load_file", path) == OK:
				midi_player.set("midi", midi_res)
	if midi_player.has_signal("note") and not midi_player.is_connected("note", _on_godot_midi_realtime_note):
		midi_player.connect("note", _on_godot_midi_realtime_note)
	return true


func start_chart_with_preroll() -> void:
	next_note_index = 0
	_spawned_keys.clear()
	song_position = -lead_time
	_audio_started = false
	_result_triggered = false
	is_running = true


func _begin_synced_playback() -> void:
	if midi_player != null:
		if audio_player != null and audio_player is AudioStreamPlayer and midi_player.has_method("link_audio_stream_player"):
			midi_player.call("link_audio_stream_player", [audio_player])
			midi_player.call("play")
			return
		elif midi_player.has_method("play"):
			midi_player.call("play")
	if audio_player != null and audio_player.has_method("play"):
		audio_player.call("play")


func _on_godot_midi_realtime_note(event: Dictionary, track: int) -> void:
	if target_track_index != -1 and track != target_track_index:
		return
	if int(event.get("subtype", 0)) == MIDI_MESSAGE_NOTE_ON:
		realtime_midi_beat.emit(int(event.get("note", 60)), track)


func _on_audio_finished() -> void:
	_trigger_result_screen()


func _trigger_result_screen() -> void:
	if _result_triggered:
		return
	_result_triggered = true
	is_running = false
	if has_node("Timer"):
		$Timer.stop()

	if typeof(GameManager) != TYPE_NIL:
		GameManager.song_finished_for_result.emit()

	var current_scene: Node = get_tree().current_scene
	if current_scene != null and current_scene.find_child("ResultScreen", true, false) == null:
		if ResourceLoader.exists("res://Scenes/result_screen.tscn"):
			get_tree().change_scene_to_file("res://Scenes/result_screen.tscn")


func _spawn_note_once(note_data: Dictionary) -> void:
	var hit_t: float = float(note_data["hit_time"])
	var lane: int = int(note_data["lane"])
	var key: String = "%d_%d" % [ int(round(hit_t * 25.0)), lane ]
	if _spawned_keys.has(key):
		return
	_spawned_keys[key] = true

	if note_scene == null:
		return
	var new_note: Node3D = note_scene.instantiate()
	if "scroll_speed" in new_note:
		new_note.scroll_speed = note_scroll_speed
	new_note.set_meta("midi_info", note_data)
	add_child(new_note)
	var clamped_lane: int = clampi(lane, 0, lanes.size() - 1)
	new_note.global_position = Vector3(lanes[clamped_lane], 0.5, spawn_z)
	note_spawned.emit(new_note, note_data)


func map_pitch_to_lane(pitch: int) -> int:
	if use_custom_pitch_map:
		if pitch == left_lane_pitch:
			return 0
		elif pitch == center_lane_pitch:
			return 1
		elif pitch == right_lane_pitch:
			return 2
		return -1
	return posmod(pitch, lanes.size())


func _on_timer_timeout() -> void:
	var random_lane: int = randi() % lanes.size()
	var new_note: Node3D = note_scene.instantiate()
	add_child(new_note)
	new_note.global_position = Vector3(lanes[random_lane], 0.5, spawn_z)
