#version 460 core

#define MAX_NUMBER_OF_TILES 512

uniform mat4 projection;
uniform vec2 tileSize;

layout (std140, binding = 3) uniform Atlas {
    int nTiles;
    vec4 tiles[MAX_NUMBER_OF_TILES];
};

in VS_OUT {
    uint gTileId;
} gs_in[];

out vec2 texCoord;

layout (points) in;
layout (triangle_strip, max_vertices = 4) out;

void main()
{
    uint tileId = gs_in[0].gTileId & 255u;
    float tileX = float(tileId & 15u) / 16.0;
    float tileY = float((tileId >> 4u) & 15u) / 16.0;

    vec4 region = tiles[gs_in[0].gTileId];

    const float B = 1.0 / 256.0;
    const float S = 1.0 / 16.0;

    gl_Position = projection * gl_in[0].gl_Position;
    texCoord = vec2(0 + B, 0 + B) * region.zw + region.xy;
    EmitVertex();

    gl_Position = projection * (gl_in[0].gl_Position + vec4(tileSize.x, 0.0, 0.0, 0.0));
    texCoord = vec2(1 - B, 0 + B) * region.zw + region.xy;
    EmitVertex();

    gl_Position = projection * (gl_in[0].gl_Position + vec4(0.0, tileSize.y, 0.0, 0.0));
    texCoord = vec2(0 + B, 1 - B) * region.zw + region.xy;
    EmitVertex();

    gl_Position = projection * (gl_in[0].gl_Position + vec4(tileSize.x, tileSize.y, 0.0, 0.0));
    texCoord = vec2(1 - B, 1 - B) * region.zw + region.xy;
    EmitVertex();

    EndPrimitive();
}