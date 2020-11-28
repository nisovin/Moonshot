shader_type canvas_item;

uniform sampler2D color_offset;
uniform sampler2D time_offset;

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float co = (texture(color_offset, UV).r - 0.5) / 4.0;
	float to = texture(time_offset, UV).r;
	if (c.a > 0.0) {
		COLOR = vec4(c.rgb, c.a + co * sin(TIME + to * 6.28));
		//COLOR = vec4(c.rgb, c.a + co);
	} else {
		COLOR = c;
	}
}