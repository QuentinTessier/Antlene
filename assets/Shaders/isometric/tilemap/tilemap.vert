#version 460 core

layout(location = 0) in vec2 v_UV;

layout (std140, binding = 0) uniform SceneData {
    mat4 projectionMatrix;
    mat4 isometricMatrix;
    mat4 orientation;
};

layout (std430, binding = 2) readonly buffer Chunk {
    vec2 WorldOffset;
    uint vertices[];
};

// TODO: Use the TileID to compute the UV of the vertex
//out float f_TileID;
out vec3 f_TileData;
out vec3 f_OriginalTileData;
out vec2 f_UV;
out float f_Depth;

vec3 getPosition(uint data)
{
    uint x = data & 0x3F;
    uint y = (data & 0xFC0) >> 6;
    uint z = (data & 0x3F000) >> 12;

    return vec3(x, y, z);
}

uint getTileId(uint data)
{
    return (data >> 18);
}

uint getVertexData()
{
    return vertices[gl_InstanceID];
}


float toRange(vec2 r1, vec2 r2, float t)
{
    return ((t - r1.x) / (r1.y - r1.x)) * (r2.y - r2.x) + r2.x;
}

void main() 
{
    uint index = gl_InstanceID;
    uint data = getVertexData();
    vec3 p = getPosition(data);

    vec4 offsets[4] = {
        vec4(0, 0, 0, 0),
        vec4(32, 0, 0, 0),
        vec4(32, 32, 0, 0),
        vec4(0, 32, 0, 0),
    };

    vec4 centered = vec4(p.xy, 0.0, 1.0) - vec4(15.5, 15.5, 0, 0);
    vec4 rotated = orientation * centered;
    vec4 offcentered = rotated + vec4(15.5, 15.5, 0, 0);

    vec4 WorldCoords = vec4(WorldOffset, 0, 1.0);

    f_TileData = vec3(offcentered.x, offcentered.y, p.z);
    f_OriginalTileData = p;
    vec4 isoPosition = (isometricMatrix * vec4(offcentered.x, offcentered.y, 0.0, 1.0)) + offsets[gl_VertexID % 4] + WorldCoords;
    vec4 baseIsoPosition = (isometricMatrix * vec4(offcentered.x, offcentered.y, 0.0, 1.0)) + WorldCoords;
    isoPosition.y += p.z * 16.0;
    baseIsoPosition.y += p.z * 16.0;

    vec4 baseVert = projectionMatrix * baseIsoPosition;
    vec4 vert = projectionMatrix * isoPosition;
    f_Depth = toRange(vec2(-1, 1), vec2(0, 1), baseVert.y) * 0.5 + abs(1.0 - p.z / 32) * 0.5;
    f_UV = v_UV * vec2(0.16666, 0.11111) + vec2(0, 0); 
    gl_Position = vec4(vert.xy, 0.0, 1.0);
}