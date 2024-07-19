#version 460 core

layout (std140, binding = 0) uniform SceneData {
    mat4 projectionMatrix;
    mat2 isometricProjection;
};

struct Tile {
    uint xy; // ushort x; ushort y;
    uint zp; // ushort z; ushort padding;
};

layout (std430, binding = 1) readonly buffer Chunk {
    Tile tiles[];
};