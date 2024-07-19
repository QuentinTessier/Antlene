const TextureHandle = @import("../Singletons/TextureRegistry.zig").TextureHandle;

pub const Sprite = @This();

region: @Vector(4, f32) = .{ 0, 0, 1, 1 },
color: @Vector(4, f32) = .{ 1, 1, 1, 1 },
handle: ?TextureHandle = null,
