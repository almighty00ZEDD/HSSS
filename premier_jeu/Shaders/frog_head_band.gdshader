shader_type canvas_item;

uniform vec4 RED1 : hint_color;
uniform vec4 RED2 : hint_color;
uniform vec4 RED3 : hint_color;


uniform vec4 BLUE1 : hint_color;
uniform vec4 BLUE2 : hint_color;
uniform vec4 BLUE3 : hint_color;


void fragment(){

	vec4 curr_color = texture(TEXTURE,UV);
	
	if(distance(curr_color, RED1) < 0.1){
		COLOR = BLUE1;
	}
	else if(distance(curr_color, RED2) < 0.1){
		COLOR = BLUE2;
	}
	else if(distance(curr_color, RED3) < 0.1){
		COLOR = BLUE3;
	}
	
	else{
		COLOR = curr_color;
	}
}