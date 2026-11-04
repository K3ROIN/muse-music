shader_type sky;

uniform vec3 top_color : source_color = vec3(0.45, 0.90, 0.75);    // สีเขียวมิ้นต์ด้านบน
uniform vec3 bottom_color : source_color = vec3(0.75, 0.98, 0.85); // สีเขียวอ่อนด้านล่าง
uniform float pattern_scale = 15.0;                                // ขนาดตารางข้าวหลามตัด

void sky() {
	// 1. คำนวณการไล่เฉดสีจากล่างขึ้นบนตามมุมกล้อง
	float horizon = clamp(EYEDIR.y * 2.0 + 0.2, 0.0, 1.0);
	vec3 bg_color = mix(bottom_color, top_color, horizon);
	
	// 2. สร้างลายตารางข้าวหลามตัด (Diamond Pattern) เฉพาะด้านบนของจอ
	vec2 uv = EYEDIR.xy * pattern_scale;
	float diamond = abs(fract(uv.x + uv.y) - 0.5) + abs(fract(uv.x - uv.y) - 0.5);
	float pattern = step(0.5, diamond);
	
	// 3. ผสมลายเข้ากับพื้นหลังอย่างนุ่มนวล
	vec3 final_color = mix(bg_color, bg_color * 0.94, pattern * horizon);
	COLOR = final_color;
}