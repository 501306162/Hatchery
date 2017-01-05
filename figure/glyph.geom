#version 410

layout (lines) in;
layout (line_strip, max_vertices = 3) out;

in float g_color_info[];
out float f_color_info;

void main()
{
  vec4 v0 = gl_in[0].gl_Position;
  vec4 v1 = gl_in[1].gl_Position;
  vec4 v2 = 0.1*(v1 - v0) + v0;

  gl_Position = gl_in[1].gl_Position;
  f_color_info = g_color_info[1];
  EmitVertex();
  gl_Position = gl_in[0].gl_Position;
  f_color_info = g_color_info[0];
  EmitVertex();
  gl_Position = v2;
  f_color_info = 0.0;
  EmitVertex();
  EndPrimitive();
}
