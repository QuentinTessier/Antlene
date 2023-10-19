const std = @import("std");
const zm = @import("zmath");
const Texture = @import("Texture.zig");

const Sprite = @This();

position: @Vector(2, f32),
size: @Vector(2, f32),
rotation: f32 = 0.0,
color: @Vector(4, f32) = .{ 1, 1, 1, 1 },
texture: ?Texture = null,
