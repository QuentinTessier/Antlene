const std = @import("std");

pub const SpriteRenderer = @This();

animation: ?struct {
    name: []const u8,
    index: usize = 0,
} = null,
origin: @Vector(2, f32) = .{ 0, 0 },
tint: @Vector(4, u8) = .{ 255, 255, 255, 255 },
flipX: bool = false,
flipY: bool = false,
order: usize,
