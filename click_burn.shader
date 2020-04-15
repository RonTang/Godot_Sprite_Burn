shader_type canvas_item;

uniform vec4 ash : hint_color;//灰烬颜色
uniform vec4 fire : hint_color;//火热颜色
uniform int OCTAVES = 5; //分形布朗运动迭代次数


uniform float start_time = 3.0;  //燃烧起始时间
uniform float duration = 5.0;    //燃烧持续时间
uniform float editor_time = 0.0; //编辑器运行时间
uniform mat4 global_transform;   //全局变换矩阵
uniform vec2 global_position;    //精灵全局坐标
uniform vec2 mouse_position;     //鼠标全局坐标
//values that from vertex to fragment
varying vec2 world_position;     //每个独立像素点全局坐标


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

//perlin（gradient）noise
float my_noise( vec2 p )
{
    vec2 i = floor( p );
    vec2 f = fract( p );
	
	vec2 u = f*f*f*(f*(f*6.0-15.0)+10.0); //f(x) = 6x^5-15x^4+10x^3 

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

	float factor = remap_range(noises,0.0,1.0,0.5,1.0);//噪声值映射到0.5-1.0
	float percent = (editor_time- start_time) / (duration * 0.5) * factor ;
	float inner_edge = percent;
	float outer_edge = inner_edge + thickness;
	
	vec2 mc_off = mouse_position - global_position;
	mc_off.x *= texture_size.x;
	mc_off.y *= texture_size.y;
	float max_dis = 0.65 + length(mc_off);//奇技淫巧确定最长燃烧距离
	
	vec2 wm_off = world_position - mouse_position;
	wm_off.x *= texture_size.x;
	wm_off.y *= texture_size.y;
	float dist =  remap_range(length(wm_off),0.0,max_dis,0.0,1.0);//燃烧距离dist映射0.0-1.0
	
	if (inner_edge > dist) //燃烧内边
		return vec4(0.0);  
	if (outer_edge > dist) //燃烧外边
	{
		//根据燃烧dist，将火焰颜色与灰烬颜色混合
		float grad_factor = (outer_edge - dist) / thickness;
		vec4 fire_grad = mix(fire, ash, grad_factor);
		//将合成颜色与物体本身颜色进行混合
		float outer_fade = (outer_edge - dist) / 0.02;
		outer_fade = clamp(outer_fade, 0.0, 1.0);
		new_col = mix(new_col, fire_grad, outer_fade);
	}
	//不会燃烧原本透明度为0的部分
	new_col.a *= original.a;	
	return new_col;
}

void fragment() {
	vec4 tex = textureLod(TEXTURE, UV, 0.0);
	COLOR = tex;
	COLOR = burn(COLOR, UV, TIME, TEXTURE_PIXEL_SIZE);
}