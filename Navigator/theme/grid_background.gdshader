shader_type canvas_item;
render_mode unshaded;

// PARALLAX navigator backdrop: deep-space gradient, technical grid, slow
// parallax stars, a soft central glow and a vignette. Cheap enough for the
// gl_compatibility renderer on integrated graphics.

uniform vec3 bg_top : source_color = vec3(0.035, 0.055, 0.10);
uniform vec3 bg_bottom : source_color = vec3(0.006, 0.010, 0.022);
uniform vec4 grid_color : source_color = vec4(0.14, 0.55, 0.72, 0.09);
uniform vec4 major_color : source_color = vec4(0.22, 0.75, 0.95, 0.14);
uniform float cell : hint_range(8.0, 256.0) = 46.0;
uniform float major_every : hint_range(2.0, 8.0) = 4.0;
uniform float scroll : hint_range(-40.0, 40.0) = 4.0;
uniform float star_density : hint_range(0.0, 0.004) = 0.0016;
uniform vec4 star_color : source_color = vec4(0.78, 0.88, 1.0, 1.0);
uniform vec4 glow_color : source_color = vec4(0.10, 0.45, 0.78, 1.0);
uniform float glow_strength : hint_range(0.0, 0.5) = 0.16;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

void fragment() {
	vec2 res = 1.0 / SCREEN_PIXEL_SIZE;
	vec2 px = UV * res;
	vec2 sc = px + vec2(0.0, TIME * scroll);

	vec3 col = mix(bg_bottom, bg_top, UV.y);

	// Grid — minor cells and brighter major lines.
	vec2 g = abs(fract(sc / cell - 0.5) - 0.5) * cell;
	float minor = 1.0 - smoothstep(0.0, 1.1, min(g.x, g.y));
	vec2 gm = abs(fract(sc / (cell * major_every) - 0.5) - 0.5) * (cell * major_every);
	float major = 1.0 - smoothstep(0.0, 1.5, min(gm.x, gm.y));
	col = mix(col, grid_color.rgb, minor * grid_color.a);
	col = mix(col, major_color.rgb, major * major_color.a);

	// Stars — sparse brightened points that twinkle slowly.
	vec2 cell_id = floor(sc / 3.0);
	float h = hash21(cell_id);
	float star = step(1.0 - star_density, h);
	vec2 f = fract(sc / 3.0) - 0.5;
	star *= 1.0 - smoothstep(0.0, 0.38, length(f));
	float twinkle = 0.55 + 0.45 * sin(TIME * 1.6 + h * 120.0);
	col += star_color.rgb * star * twinkle * 0.8;

	// Soft central glow behind the map.
	vec2 d = UV - vec2(0.56, 0.44);
	col += glow_color.rgb * exp(-dot(d, d) * 3.0) * glow_strength;

	// Vignette + faint scanlines.
	float vig = smoothstep(1.25, 0.30, length(UV - vec2(0.5)));
	col *= mix(0.52, 1.0, vig);
	col *= 0.975 + 0.025 * sin(px.y * 1.3);

	COLOR = vec4(col, 1.0);
}