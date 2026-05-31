shader_type canvas_item;

uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
    COLOR = vec4(mix(COLOR.rgb, vec3(1.0), flash_amount), COLOR.a);
}
