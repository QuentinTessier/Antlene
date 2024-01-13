const std = @import("std");

const Mat4x4 = @import("root.zig").Mat4x4;

const Vec3 = @import("root.zig").Vec3;
const vec3 = @import("root.zig").vec3;

const Vec4 = @import("root.zig").Vec4;
const vec4 = @import("root.zig").vec4;

const BiVec3 = Vec3;

pub inline fn wEdge(u: vec3, v: vec3) vec3 {
    return Vec3.init(.{
        .x = u[0] * v[1] - u[1] * v[0],
        .y = u[0] * v[2] - u[2] * v[0],
        .z = u[1] * v[2] - u[2] * v[1],
    });
}

pub const Rotor = struct {
    pub const Type = vec4;

    pub inline fn identity() vec4 {
        return Vec4.init(.{ .x = 1, .y = 0, .z = 0, .w = 0 });
    }

    pub inline fn init(a: f32, bv: vec3) vec4 {
        return Vec4.init(.{ .x = a, .y = bv[0], .z = bv[0], .w = bv[0] });
    }

    pub inline fn initFromTo(from: vec3, to: vec3) vec4 {
        const a = 1.0 + Vec3.dot(to, from);
        const bv = wEdge(to, from);
        return Vec4.normalize(init(a, bv));
    }

    pub inline fn initAnglePlane(bvPlane: vec3, radians: f32) vec4 {
        const sina = std.math.sin(radians * 0.5);
        const a = std.math.cos(radians * 0.5);
        const bv = BiVec3.init(.{
            .x = -sina * bvPlane[0],
            .y = -sina * bvPlane[1],
            .z = -sina * bvPlane[2],
        });
        return init(a, bv);
    }

    pub inline fn mul(r1: vec4, r2: vec4) vec4 {
        return Vec4.init(.{
            .x = r1[0] * r2[0] - r1[1] * r2[1] - r1[2] * r2[2] - r1[3] * r2[3],
            .y = r1[1] * r2[0] + r1[0] * r2[1] + r1[3] * r2[2] - r1[2] * r2[3],
            .z = r1[2] * r2[0] + r1[0] * r2[2] - r1[3] * r2[1] + r1[1] * r2[3],
            .w = r1[3] * r2[0] + r1[0] * r2[3] + r1[2] * r2[1] - r1[1] * r2[2],
        });
    }

    pub inline fn rotateVec(r: vec4, v: vec3) vec3 {
        const q = Vec3.init(.{
            .x = r[0] * v[0] + v[1] * r[1] + v[2] * r[2],
            .y = r[0] * v[1] + v[0] * r[1] + v[2] * r[3],
            .z = r[0] * v[2] + v[0] * r[2] + v[1] * r[3],
        });
        const q012 = v[0] * r[3] - v[1] * r[2] + v[2] * r[1];

        return Vec3.init(.{
            .x = r[0] * q[0] + q[1] * r[1] + q[2] * r[2] + q012 * r[3],
            .y = r[0] * q[1] - q[0] * r[1] - q012 * r[2] + q[2] * r[3],
            .z = r[0] * q[2] + q012 * r[1] - q[0] * r[2] - q[1] * r[3],
        });
    }

    pub inline fn reverse(r1: vec4) vec4 {
        return r1 * Vec4.init(.{ .x = 1, .y = -1, .z = -1, .w = -1 });
    }

    pub inline fn rotate(r1: vec4, r2: vec4) vec4 {
        const rev = reverse(r1);
        return mul(r1, mul(r2, rev));
    }

    pub inline fn lengthSq(r1: vec4) f32 {
        return Vec4.lengthSq(r1);
    }

    pub inline fn length(r: vec4) f32 {
        return Vec4.length(r);
    }

    pub inline fn normalize(r: vec4) vec4 {
        return Vec4.normalize(r);
    }

    pub inline fn toMat4x4(r: vec4) Mat4x4.MatrixType {
        const row0 = rotateVec(r, .{ 1, 0, 0 });
        const row1 = rotateVec(r, .{ 0, 1, 0 });
        const row2 = rotateVec(r, .{ 0, 0, 1 });
        return Mat4x4.init(.{
            @as([3]f32, row0) ++ [1]f32{0},
            @as([3]f32, row1) ++ [1]f32{0},
            @as([3]f32, row2) ++ [1]f32{0},
            .{ 0, 0, 0, 1 },
        });
    }
};
