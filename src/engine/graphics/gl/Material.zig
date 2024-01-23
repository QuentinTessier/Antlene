const std = @import("std");
const Math = @import("AntleneMath");
const Texture = @import("Texture.zig");

pub const Material = @This();

diffuse: Texture,
specular: Texture,
ambient: Math.vec3,
shininess: f32,
