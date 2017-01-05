#version 410

layout(location = 0) in vec2 vertex_position;
layout(location = 1) in float strip_length;

uniform mat4 model, view, proj;

out float g_color_info;

void main() {
	gl_Position =  proj * view * model * vec4(vertex_position, 0, 1.0);
	g_color_info = strip_length;
}
