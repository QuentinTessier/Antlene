const std = @import("std");
const Math = @import("AntleneMath");
const Texture = @import("Texture.zig");

pub const Material = @This();

diffuse: Texture,
specular: Texture,
normal: Texture,
shininess: f32,
tilingFactor: f32 = 1.0,
