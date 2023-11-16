const std = @import("std");
const Texture = @import("./Graphics/Texture.zig");
const Sprite = @import("./Graphics/Sprite.zig");

pub const SceneBase = struct {
    name: []const u8,

    // Methods
    update: ?*const fn (*SceneBase, f64) anyerror!void,
    draw: ?*const fn (*SceneBase) void,

    textures: std.StringHashMapUnmanaged(Texture),
    sprites: std.StringArrayHashMapUnmanaged(Sprite),
};
