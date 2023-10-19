const std = @import("std");
const gl = @import("Platform/gl/gl.zig");

pub const Texture = @import("Graphics/Texture.zig");
pub const Shader = @import("Graphics/Shader.zig");
pub const Buffer = @import("Graphics/Buffer.zig");
pub const VertexArray = @import("Graphics/VertexArray.zig");

pub fn setClearColor(color: @Vector(4, f32)) void {
    gl.clearColor(color[0], color[1], color[2], color[3]);
}

// TODO: Be able to specify which buffer to clear
pub fn clear() void {
    gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
}

pub fn setViewport(width: i32, height: i32) void {
    gl.viewport(0, 0, width, height);
}
