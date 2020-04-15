tool
extends Sprite
func _ready():
	set_process(true)
	
func _process(delta):
	material.set_shader_param('editor_time',OS.get_ticks_msec()/1000.0)
	material.set_shader_param('center_position',global_position);
	if Input.is_mouse_button_pressed(BUTTON_LEFT):
		material.set_shader_param('global_transform',global_transform);
		material.set_shader_param('mouse_position',get_global_mouse_position());
		material.set_shader_param('start_time', OS.get_ticks_msec()/1000.0);
		material.set_shader_param('duration',2.0);
	
