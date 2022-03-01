shader_type canvas_item;

uniform vec4 BASE : hint_color;
uniform vec4 BASE2 : hint_color;

uniform vec4 NEW : hint_color;

void fragment(){

	vec4 curr_color = texture(TEXTURE,UV);
	
	if(distance(curr_color, BASE) < 0.1){
		COLOR = NEW;
	}
	else if(distance(curr_color, BASE2) < 0.1){
		COLOR = NEW;
	}
	
	else{
		COLOR = curr_color;
	}
}