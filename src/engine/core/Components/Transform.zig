const std = @import("std");
const Math = @import("AntleneMath");

pub const Transform = @This();

dirty: bool = false,

position: Math.vec3 = .{ 0, 0, 0 },
scale: Math.vec3 = .{ 1, 1, 1 },
rotation: Math.vec3 = .{ 0, 0, 0 }, // TODO: Use a Rotor

model_matrix: Math.mat4x4 = Math.Mat4x4.identity(),

pub fn compute(self: Transform) Math.mat4x4 {
    if (!self.dirty) return self.model_matrix;

    const x = Math.Mat4x4.rotateX(self.rotation[0]);
    const y = Math.Mat4x4.rotateY(self.rotation[1]);
    const z = Math.Mat4x4.rotateZ(self.rotation[2]);
    const rotation = Math.Mat4x4.mul(x, Math.Mat4x4.mul(y, z)); // TODO: Use a Rotor
    const scale = Math.Mat4x4.scale(self.scale);
    const translation = Math.Mat4x4.translate(self.position);

    self.model_matrix = Math.Mat4x4.mul(scale, Math.Mat4x4.mul(rotation, translation));

    self.dirty = false;
}
