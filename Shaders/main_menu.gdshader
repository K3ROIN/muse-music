shader_type canvas_item;

uniform vec3 color_one : source_color = vec3(1.0, 0.0, 0.23);
uniform vec3 color_two : source_color = vec3(0.05, 0.05, 0.05);
uniform float angle = 35.0;
uniform float line_count = 14.0;
uniform float speed = 3.0;
uniform float blur : hint_range(0.0, 2.0) = 0.02;

// พารามิเตอร์สำหรับควบคุมคลื่นและแรงกระเพื่อม
uniform float wave_frequency = 6.0;
uniform float wave_amplitude = 0.15;
uniform float wave_speed = 2.5;

vec2 rotate(vec2 uv, float rotation_angle) {
    float radians_angle = radians(rotation_angle);
    float cos_angle = cos(radians_angle);
    float sin_angle = sin(radians_angle);
    mat2 rotation_matrix = mat2(vec2(cos_angle, -sin_angle), vec2(sin_angle, cos_angle));
    return uv * rotation_matrix;
}

float stripe(vec2 uv) {
    // เพิ่ม TIME * wave_speed เพื่อให้คลื่นขยับพลิ้วไหวตลอดเวลา
    float wave = sin(uv.x * wave_frequency + TIME * wave_speed) * wave_amplitude;
    return cos(-TIME * speed + (uv.y + wave) * -line_count / 2.0);
}

void fragment() {
    vec2 uv = UV;
    float a = TEXTURE_PIXEL_SIZE.x / TEXTURE_PIXEL_SIZE.y;
    uv.x *= a;
    uv = rotate(uv, angle);
    float g = stripe(uv);
    vec3 col = mix(color_one, color_two, smoothstep(0.0, blur, g));
    COLOR = vec4(col, 1.0);
}
