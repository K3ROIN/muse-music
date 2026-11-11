extends CanvasItem

@export var freq_min: float = 500.0      # ความถี่ต่ำสุด (Hz) - ค่าเริ่มต้นสำหรับเสียงร้อง
@export var freq_max: float = 1500.0     # ความถี่สูงสุด (Hz)
@export var min_amplitude: float = 0.08  # ความสูงคลื่นปกติตอนเพลงเงียบ
@export var max_amplitude: float = 0.35  # ความสูงคลื่นสูงสุดตอนเสียงดัง
@export var sensitivity: float = 40.0    # เพิ่มตัวคูณให้สูงขึ้นเพราะเสียงร้องเบากว่าเบส
@export var smooth_speed: float = 15.0   # เพิ่มความไวในการยุบตัวให้ทันจังหวะเสียงร้อง

var spectrum: AudioEffectSpectrumAnalyzerInstance
var current_amplitude: float = 0.08

func _ready() -> void:
	spectrum = AudioServer.get_bus_effect_instance(0, 0)
	current_amplitude = min_amplitude

func _process(delta: float) -> void:
	if not spectrum:
		return
	
	# ดึงค่าความดังตามช่วงความถี่ที่ตั้งไว้ (เสียงร้อง/เสียงแหลม)
	var magnitude: float = spectrum.get_magnitude_for_frequency_range(freq_min, freq_max).length()
	
	var target_amp: float = clamp(min_amplitude + (magnitude * sensitivity), min_amplitude, max_amplitude)
	current_amplitude = lerp(current_amplitude, target_amp, smooth_speed * delta)
	
	var mat := material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("wave_amplitude", current_amplitude)
