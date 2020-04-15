shader_type canvas_item;


uniform vec4 ash : hint_color;
uniform vec4 fire : hint_color;

uniform int OCTAVES = 5;

// values that need to be set from a script
uniform float start_time = 3.0;
uniform float duration = 5.0;
uniform float editor_time = 0.0;
uniform mat4 global_transform;
uniform vec2 center_position;
uniform vec2 mouse_position;
varying vec2 world_position;


float remap_range(float input, float minInput, float maxInput, float minOutput, float maxOutput)
{
	return(input - minInput) / (maxInput - minInput) * (maxOutput - minOutput) + minOutput;
}

void vertex(){
    world_position = (global_transform * vec4(VERTEX, 0.0, 1.0)).xy;
}

vec2 random ( vec2 st) {
	float x = -1.0+ 2.0*fract(sin(dot(st.xy,
                         vec2(12.9898,78.233)))
                 * 43758.5453123);
	float y = -1.0+ 2.0*fract(sin(dot(st.xy,
                         vec2(78.233,12.9898)))
                 * 43758.5453123);
    return vec2(x,y);
}


float my_noise( vec2 p )
{
    vec2 i = floor( p );
    vec2 f = fract( p );
	
	vec2 u = f*f*f*(f*(f*6.0-15.0)+10.0);

    return mix( mix( dot( random( i + vec2(0.0,0.0) ), f - vec2(0.0,0.0) ), 
                     dot( random( i + vec2(1.0,0.0) ), f - vec2(1.0,0.0) ), u.x),
                mix( dot( random( i + vec2(0.0,1.0) ), f - vec2(0.0,1.0) ), 
                     dot( random( i + vec2(1.0,1.0) ), f - vec2(1.0,1.0) ), u.x), u.y);
}

float fbm(vec2 coord){
	float value = 0.0;
	float scale = 0.5;

	for(int i = 0; i < OCTAVES; i++){
		value += my_noise(coord) * scale;
		coord *= 2.0;
		scale *= 0.5;
	}
	return value;
}

vec4 burn(vec4 original, vec2 uv, float time, vec2 texture_size) {
	
	vec4 new_col = original; 
	
	float noises = fbm(uv * 16.0);

	float thickness = 0.1;

	float factor = remap_range(noises,0.0,1.0,0.5,1.0);
	float percent = (editor_time- start_time) / (duration * 0.5) * factor ;
	
	vec2 mc_off = mouse_position - center_position;
	mc_off.x *= texture_size.x;
	mc_off.y *= texture_size.y;
	float max_dis = 0.7+ length(mc_off);
	
	vec2 wm_off = world_position - mouse_position;
	wm_off.x *= texture_size.x;
	wm_off.y *= texture_size.y;
	float outer_edge = percent;
	float inner_edge = outer_edge + thickness;
	float dist =  remap_range(length(wm_off),0.0,max_dis,0.0,1.0);
	if (outer_edge > dist)
		return vec4(0.0);
	if (inner_edge > dist)
	{
		float grad_factor = (inner_edge - dist) / thickness;
		grad_factor = clamp(grad_factor, 0.0, 1.0);
		vec4 fire_grad = mix(fire, ash, grad_factor);
		float inner_fade = (inner_edge - dist) / 0.02;
		inner_fade = clamp(inner_fade, 0.0, 1.0);
		new_col = mix(new_col, fire_grad, inner_fade);
	}
	new_col.a *= original.a;	
	return new_col;
}

void fragment() {
	vec4 tex = textureLod(TEXTURE, UV, 0.0);
	COLOR = tex;
	COLOR = burn(COLOR, UV, TIME, TEXTURE_PIXEL_SIZE);
}