const std = @import("std");
const Math = @import("AntleneMath");

pub const ActiveCamera = u8;

pub const Camera = @This();

offset: @Vector(2, f32) = .{ 0, 0 },
target: @Vector(2, f32) = .{ 0, 0 },
rotation: f32 = 0.0,
zoom: f32 = 1.0,
near: f32 = 0.1,
far: f32 = 100.0,

hasChanged: bool = true, // TODO: Enable lazy recompute
vp: Math.mat4x4 = Math.Mat4x4.identity(),

pub fn getViewMatrix(self: Camera) Math.mat4x4 {
    const origin = Math.Mat4x4.translate(.{ -self.target[0], -self.target[1], 0.0 });
    const rotation = Math.Mat4x4.rotateZ(Math.degreesToRadians(self.rotation));
    const scale = Math.Mat4x4.scale(.{ self.zoom, self.zoom, 1.0 });
    const translate = Math.Mat4x4.translate(.{ -self.offset[0], -self.offset[1], 0.0 });

    return Math.Mat4x4.mul(Math.Mat4x4.mul(origin, Math.Mat4x4.mul(scale, rotation)), translate);
}

pub fn getProjectionMatrix(self: Camera, width: f32, height: f32) Math.mat4x4 {
    const left = -width * 0.5;
    const right = width * 0.5;

    const bottom = -height * 0.5;
    const top = height * 0.5;

    return Math.orthographic(left, right, bottom, top, self.near, self.far);
}

pub fn getViewProjection(self: *Camera, width: f32, height: f32) Math.mat4x4 {
    if (self.hasChanged) {
        const view = self.getViewMatrix();
        const proj = self.getProjectionMatrix(width, height);

        self.vp = Math.Mat4x4.mul(proj, view);
    }
    return self.vp;
}
