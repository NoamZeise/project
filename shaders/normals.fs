#version 460

in vec3 fpos;
in vec3 fnorm;
in vec2 fuv;
out vec4 colour;

void main() {
  colour = (vec4(normalize(fnorm), 1) + vec4(1))/2;
}
