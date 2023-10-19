#version 460 core

in vec2 f_TexCoord;
in vec4 f_Color;
in float f_TilingFactor;
in float f_TexIndex;

uniform sampler2D u_Textures[16];

out vec4 p_Color;

void main() {
    vec4 texColor = f_Color;

    switch (int(f_TexIndex)) {
        case  0: texColor *= texture(u_Textures[ 0], f_TexCoord * f_TilingFactor); break;
        case  1: texColor *= texture(u_Textures[ 1], f_TexCoord * f_TilingFactor); break;
        case  2: texColor *= texture(u_Textures[ 2], f_TexCoord * f_TilingFactor); break;
        case  3: texColor *= texture(u_Textures[ 3], f_TexCoord * f_TilingFactor); break;
        case  4: texColor *= texture(u_Textures[ 4], f_TexCoord * f_TilingFactor); break;
        case  5: texColor *= texture(u_Textures[ 5], f_TexCoord * f_TilingFactor); break;
        case  6: texColor *= texture(u_Textures[ 6], f_TexCoord * f_TilingFactor); break;
        case  7: texColor *= texture(u_Textures[ 7], f_TexCoord * f_TilingFactor); break;
        case  8: texColor *= texture(u_Textures[ 8], f_TexCoord * f_TilingFactor); break;
        case  9: texColor *= texture(u_Textures[ 9], f_TexCoord * f_TilingFactor); break;
        case 10: texColor *= texture(u_Textures[10], f_TexCoord * f_TilingFactor); break;
        case 11: texColor *= texture(u_Textures[11], f_TexCoord * f_TilingFactor); break;
        case 12: texColor *= texture(u_Textures[12], f_TexCoord * f_TilingFactor); break;
        case 13: texColor *= texture(u_Textures[13], f_TexCoord * f_TilingFactor); break;
        case 14: texColor *= texture(u_Textures[14], f_TexCoord * f_TilingFactor); break;
        case 15: texColor *= texture(u_Textures[15], f_TexCoord * f_TilingFactor); break;
    }
    p_Color = texColor;
}