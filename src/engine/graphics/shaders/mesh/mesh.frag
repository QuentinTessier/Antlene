#version 460 core

layout(location = 0) in vec3 f_Position;
layout(location = 1) in vec3 f_Normal;
layout(location = 2) in vec2 f_TexCoords;
layout(location = 3) in vec3 f_Tangent;

layout(location = 0) out vec4 r_Color;

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

layout(binding = 0) uniform sampler2D diffuse;
layout(binding = 1) uniform sampler2D specular;
layout(binding = 2) uniform sampler2D normal;

vec3 getBumpedNormal()
{
    vec3 normal1 = normalize(f_Normal);
    vec3 tangent = normalize(f_Tangent);
    tangent = normalize(tangent - dot(tangent, normal1) * normal1);
    vec3 bitangent = cross(tangent, normal1);
    vec3 bumpNormal = vec3(2.0) * texture(normal, f_TexCoords * tilingFactor).rgb - vec3(1.0);
    mat3 TBN = mat3(tangent, bitangent, normal1);
    return normalize(TBN * bumpNormal);
}

void main()
{
    vec3 lightPosition = vec3(0, 20, 0);
    vec3 lightColor = vec3(1.0, 1.0, 1.0);

    vec3 sDiffuse = texture(diffuse, f_TexCoords * tilingFactor).rgb;
    vec3 sSpecular = texture(specular, f_TexCoords * tilingFactor).rgb;
    vec3 sAmbient = sDiffuse;

    vec3 norm = getBumpedNormal();
    vec3 lightDir = normalize(lightPosition - f_Position);
    float diff = max(dot(norm, lightDir * sDiffuse), 0.0);
    vec3 diffuse = diff * lightColor;

    vec3 viewDir = normalize(viewPosition - f_Position);
    vec3 reflectDir = reflect(-lightDir, norm);
    float spec = pow(max(dot(viewDir, reflectDir), 0.0), shininess);
    vec3 specular = lightColor * (spec * sSpecular);

    r_Color = vec4(diffuse + specular + sAmbient, 1.0);
}