#version 460 core

layout(location = 0) in vec3 v_Position;
layout(location = 1) in vec3 v_Normal;
layout(location = 2) in vec2 v_TexCoords;

layout(location = 0) out vec3 f_Position;
layout(location = 1) out vec3 f_Normal;
layout(location = 2) out vec2 f_TexCoords;

layout(std140, binding = 0) uniform CameraTransforms {
    mat4 projection;
    mat4 view;
};

layout(std140, binding = 1) uniform Mesh {
    mat4 model;
    vec4 color;
    mat3 normalMatrix;
};

void main()
{
    f_Position = vec3(model * vec4(v_Position, 1.0));
    f_TexCoords = v_TexCoords;
    f_Normal = normalMatrix * v_Normal;
    gl_Position = projection * view * model * vec4(v_Position, 1.0);
}
