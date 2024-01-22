#version 460 core

layout(location = 0) in vec3 f_Position;
layout(location = 1) in vec3 f_Normal;
layout(location = 2) in vec2 f_TexCoords;

layout(location = 0) out vec4 r_Color;

layout(binding = 0, std140) uniform SceneData {
    mat4 projection;
    mat4 view;
    vec3 viewPosition;
};

layout(binding = 1, std140) uniform MeshData {
    vec4 ambient;
    vec4 shininess;
    mat4 model;
    mat4 normal;
};

layout(binding = 0) uniform sampler2D diffuse;
layout(binding = 1) uniform sampler2D specular;


void main()
{
    vec3 lightPosition = vec3(0, 3, -2);
    vec3 lightColor = vec3(1.0, 1.0, 1.0);

    vec3 sDiffuse = texture(diffuse, f_TexCoords).rgb;
    vec3 sSpecular = texture(specular, f_TexCoords).rgb;
    vec3 sAmbient = sDiffuse;

    vec3 norm = normalize(f_Normal);
    vec3 lightDir = normalize(lightPosition - f_Position);
    float diff = max(dot(norm, lightDir * sDiffuse), 0.0);
    vec3 diffuse = diff * lightColor;

    vec3 viewDir = normalize(viewPosition - f_Position);
    vec3 reflectDir = reflect(-lightDir, norm);
    float spec = pow(max(dot(viewDir, reflectDir), 0.0), shininess.x);
    vec3 specular = lightColor * (spec * sSpecular);

    r_Color = ambient;
}