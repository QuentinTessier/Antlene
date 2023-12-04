const std = @import("std");

pub const Atlas = @This();

const Texture = @import("../../Graphics/Texture.zig");

texture: Texture,
regions: std.ArrayListUnmanaged(@Vector(4, f32)) = .{},

pub fn deinit(self: *Atlas, allocator: std.mem.Allocator) void {
    self.regions.deinit(allocator);
    self.texture.unload(allocator);
}
