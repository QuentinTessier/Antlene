#version 460 core

out vec2 f_TexCoord;
out vec4 f_Color;
out float f_TilingFactor;
out float f_TexIndex;

layout (std140, binding = 0) uniform Projection {
    mat4 projectionMatrix;
};

struct Vertex {
    float position[2];
    float texCoord[2];
    float color[4];
    float tilingFactor;
    float texIndex;
};

layout(std430, binding = 1) readonly buffer ssbo1 {
    Vertex vertices[];
};

vec2 getPosition(int index)
{
    return vec2(
        vertices[gl_VertexID].position[0],
        vertices[gl_VertexID].position[1]
    );
}

vec2 getTexCoords(int index)
{
    return vec2(
        vertices[gl_VertexID].texCoord[0],
        vertices[gl_VertexID].texCoord[1]
    );
}

vec4 getColor(int index)
{
    return vec4(
        vertices[gl_VertexID].color[0],
        vertices[gl_VertexID].color[1],
        vertices[gl_VertexID].color[2],
        vertices[gl_VertexID].color[3]
    );
}

float getTilingFactor(int index)
{
    return vertices[gl_VertexID].tilingFactor;
}

float getTextureIndex(int index)
{
    return vertices[gl_VertexID].texIndex;
}

void main() {
    f_TexCoord = getTexCoords(gl_VertexID);
    f_Color = getColor(gl_VertexID);
    f_TilingFactor = getTilingFactor(gl_VertexID);
    f_TexIndex = getTextureIndex(gl_VertexID);

    vec4 pos = projectionMatrix * vec4(getPosition(gl_VertexID), 0.0, 1.0);
    gl_Position = vec4(pos.xyz, 1.0);
}