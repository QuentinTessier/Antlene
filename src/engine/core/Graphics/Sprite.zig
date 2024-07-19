const Graphics = @import("AntleneOpenGL");
const Math = @import("AntleneMath");

pub const Sprite = @This();

position: @Vector(2, f32) = .{ 0.0, 0.0 },
size: @Vector(2, f32) = .{ 1.0, 1.0 },
rotation: f32 = 0,
color: @Vector(4, f32) = .{ 1.0, 1.0, 1.0, 1.0 },
region: @Vector(4, f32) = .{ 0.0, 0.0, 1.0, 1.0 },
texture: ?Graphics.Texture = null,

pub fn getTransform(self: Sprite) Math.mat4x4 {
    var model = Math.Mat4x4.identity();

    model = Math.Mat4x4.mul(model, Math.Mat4x4.translate(.{ self.position[0], self.position[1], 0.0 }));
    model = Math.Mat4x4.mul(model, Math.Mat4x4.rotateZ(Math.degreesToRadians(self.rotation)));
    model = Math.Mat4x4.mul(model, Math.Mat4x4.scale(.{ self.size[0], self.size[1], 1.0 }));

    return model;
}
