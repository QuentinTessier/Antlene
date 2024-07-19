const Math = @import("AntleneMath");

pub const Transform = @This();

position: @Vector(3, f32) = .{ 0, 0, 0 },
scale: @Vector(2, f32) = .{ 1, 1 },
rotation: f32 = 0,

pub fn getMatrix(self: Transform) Math.mat4x4 {
    var model = Math.Mat4x4.translate(self.position);
    model = Math.Mat4x4.mul(model, Math.Mat4x4.rotateZ(Math.degreesToRadians(self.rotation)));
    model = Math.Mat4x4.mul(model, Math.Mat4x4.scale(.{ self.scale[0], self.scale[1], 1.0 }));

    return model;
}
