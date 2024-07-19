const Math = @import("AntleneMath");

pub const Transform = @This();

position: @Vector(3, f32),
scale: @Vector(2, f32),
rotation: f32,
