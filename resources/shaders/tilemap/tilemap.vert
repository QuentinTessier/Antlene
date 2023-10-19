#version 460 core

uniform mat4 projection;
uniform ivec2 mapSize;
uniform vec2 tileSize;
uniform vec2 chunkPosition;

layout (location = 0) in uint tileId;

out VS_OUT {
    uint gTileId;
} vs_out;

void main()
{
    int i = gl_VertexID;
    float x = float(i & 15u);
    float y = float((i >> 4u) & 15u);
    gl_Position = vec4(x * tileSize.x + chunkPosition.x, y * tileSize.y+ chunkPosition.y, 0.9, 1);

    vs_out.gTileId = tileId;
}