#version 460 core

layout (std140, binding = 0) uniform SceneData {
    mat4 projectionMatrix;
    mat4 isometricMatrix;
};

struct Vertex {
    float position[4];
    float uv[2];
};

layout (std430, binding = 1) readonly buffer Tiles {
    Vertex vertices[];
};

out vec3 f_TileData;
out vec3 f_OriginalTileData;
out vec2 f_UV;
out float f_Depth;

float toRange(vec2 r1, vec2 r2, float t)
{
    return ((t - r1.x) / (r1.y - r1.x)) * (r2.y - r2.x) + r2.x;
}

void main()
{
    f_TileData = vec3(0, 0, 0);
    f_OriginalTileData = vec3(0, 0, 0);
    f_UV = vec2(vertices[gl_VertexID].uv[0], vertices[gl_VertexID].uv[1]);
    uint vertex = gl_VertexID - (gl_VertexID % 4);

    vec4 offsets[4] = {
        vec4(0, 0, 0, 0),
        vec4(32, 0, 0, 0),
        vec4(32, 32, 0, 0),
        vec4(0, 32, 0, 0),
    };

    vec2 p = vec2(vertices[vertex].position[0], vertices[vertex].position[1]);
    float zOffset = vertices[vertex].position[2] * 16.0;
    vec4 noDepth = vec4(p.x, p.y, 0.0, 1.0);
    vec4 isoPosition = (isometricMatrix * noDepth) + offsets[gl_VertexID % 4];
    isoPosition.y += zOffset;

    vec4 test = projectionMatrix * isometricMatrix * noDepth;
    vec4 vert = projectionMatrix * isoPosition;
    f_Depth = toRange(vec2(-1, 1), vec2(0, 1), test.y) * 0.5 + abs(1.0 - vertices[vertex].position[2] / 32) * 0.5;
    gl_Position = vec4(vert.xy, 0.0, 1.0);
}