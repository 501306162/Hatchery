#version 410

layout(location = 0) in vec2 vertex_position;
uniform mat4 model, view, proj;

void main() {
	gl_Position =  proj * view * model * vec4(vertex_position, 0.0, 1.0);
}
