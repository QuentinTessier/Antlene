#version 460 core

in vec3 f_TileData;
in vec3 f_OriginalTileData;
in vec2 f_UV;
in float f_Depth;

out vec4 f_FragColor;

uniform sampler2D u_Tileset;

void main()
{
    vec4 color = texture(u_Tileset, f_UV);
    if (color.a <= 0.01) {
        discard;
    }
    gl_FragDepth = f_Depth;
    f_FragColor = color;
}