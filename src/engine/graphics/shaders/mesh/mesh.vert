#version 460 core

layout(location = 0) in vec3 v_Position;
layout(location = 1) in vec3 v_Normal;
layout(location = 2) in vec2 v_TexCoords;
layout(location = 3) in vec3 v_Tangent;

layout(location = 0) out vec3 f_Position;
layout(location = 1) out vec3 f_Normal;
layout(location = 2) out vec2 f_TexCoords;
layout(location = 3) out vec3 f_Tangent;

layout(binding = 0, std140) uniform SceneData {
    mat4 projection;
    mat4 view;
    vec3 viewPosition;
};

layout(binding = 1, std140) uniform MeshData {
    mat4 model;
    float shininess;
    float tilingFactor;
};

void main()
{
    f_Position = vec3(model * vec4(v_Position, 1.0));
    f_Normal = vec3(model * vec4(v_Normal, 1.0));
    f_Tangent = vec3(model * vec4(v_Tangent, 1.0));
    f_TexCoords = v_TexCoords;

    gl_Position = projection * view * model * vec4(v_Position, 1.0);
}
