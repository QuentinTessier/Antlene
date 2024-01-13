#version 460 core

layout(location = 0) in vec3 f_Position;
layout(location = 1) in vec3 f_Normal;
layout(location = 2) in vec2 f_TexCoords;

layout(location = 0) out vec4 r_Color;

layout(std140, binding = 1) uniform Mesh {
    mat4 model;
    vec4 color;
    mat3 normalMatrix;
};

void main()
{
    r_Color = color;
}