const std = @import("std");
const rl = @import("raylib");

pub fn toRectangle(v: @Vector(4, f32)) rl.Rectangle {
    return .{ .x = v[0], .y = v[1], .width = v[2], .height = v[3] };
}

pub fn fromRectangle(rec: rl.Rectangle) @Vector(4, f32) {
    return .{ rec.x, rec.y, rec.width, rec.height };
}

pub fn toVector2(v: @Vector(2, f32)) rl.Vector2 {
    return .{ .x = v[0], .y = v[1] };
}

pub fn fromVector2(v: rl.Vector2) @Vector(2, f32) {
    return .{ v.x, v.y };
}

pub fn toVector3(v: @Vector(3, f32)) rl.Vector3 {
    return .{ .x = v[0], .y = v[1], .z = v[2] };
}

pub fn fromVector3(v: rl.Vector3) @Vector(3, f32) {
    return .{ v.x, v.y, v.z };
}

pub fn toColor(c: @Vector(4, u8)) rl.Color {
    return .{ .r = c[0], .g = c[1], .b = c[2], .a = c[3] };
}

pub fn fromColor(c: rl.Color) @Vector(4, u8) {
    return .{ c.r, c.g, c.b, c.a };
}
