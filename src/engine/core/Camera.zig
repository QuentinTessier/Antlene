const std = @import("std");
const zm = @import("zmath");
//const Bounds = @import("Physics/Bounds.zig");

pub const Camera = struct {
    position: @Vector(2, f32),
    zoom: f32 = 1.0,
    width: f32 = 0,
    height: f32 = 0,
    nearfar: @Vector(2, f32) = .{ 0.1, 1000.0 },

    projection: zm.Mat = zm.identity(),

    pub fn buildProjection(self: *Camera) void {
        const width = self.width;
        const height = self.height;
        const left: f32 = self.position[0] - width * 0.5;
        const right: f32 = self.position[0] + width * 0.5;
        const bottom: f32 = self.position[1] - height * 0.5;
        const top: f32 = self.position[1] + height * 0.5;

        const ortho = zm.orthographicOffCenterLh(left, right, bottom, top, self.nearfar[0], self.nearfar[1]);
        const scale = zm.scaling(self.zoom, self.zoom, 1.0);
        self.projection = zm.mul(ortho, scale);
    }
};
