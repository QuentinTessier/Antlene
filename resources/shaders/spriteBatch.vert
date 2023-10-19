#version 460 core

layout(location = 0) in vec2 v_Pos;
layout(location = 1) in vec2 v_TexCoord;
layout(location = 2) in vec4 v_Color;
layout(location = 3) in float v_TilingFactor;
layout(location = 4) in float v_TexIndex;

out vec2 f_TexCoord;
out vec4 f_Color;
out float f_TilingFactor;
out float f_TexIndex;

layout (std140, binding = 0) uniform Projection {
    mat4 projectionMatrix;
};

void main() {
    f_TexCoord = v_TexCoord;
    f_Color = v_Color;
    f_TilingFactor = v_TilingFactor;
    f_TexIndex = v_TexIndex;

    gl_Position = projectionMatrix * vec4(v_Pos, 0.0, 1.0);
}