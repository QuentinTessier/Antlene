const std = @import("std");
const rl = @import("raylib");
const Texture = @import("Texture.zig").Texture;
const Animation = @import("Animation.zig");
const Utils = @import("Utils.zig");
pub const Sprite = @This();

const Source = union(enum(u32)) {
    none: void,
    animation: *Animation,
    texture: Texture,
};

const OriginStrategy = enum {
    TopLeft,
    TopRight,
    BottomLeft,
    BottomRight,
    Centered,
};

origin: @Vector(2, f32) = .{ 0, 0 },
region: @Vector(4, f32) = .{ 0, 0, 1, 1 },
color: @Vector(4, u8) = .{ 255, 255, 255, 255 },
source: Source,

pub fn update(self: *Sprite, deltaTime: f32) void {
    switch (self.source) {
        .animation => |animation| {
            if (animation.update(deltaTime)) |new_region| {
                self.region = new_region;
            }
        },
        else => {},
    }
}

const SpriteInitData = struct {
    source: Source,
    region: ?@Vector(4, f32) = null,
    color: @Vector(4, u8) = .{ 255, 255, 255, 255 },
    originStrategy: OriginStrategy = .Centered,
};

pub fn init(data: SpriteInitData) Sprite {
    const region = if (data.region) |r| r else switch (data.source) {
        .none => @Vector(4, f32){ 0, 0, 1, 1 },
        .texture => |texture| @Vector(4, f32){ 0, 0, @as(f32, @floatFromInt(texture.handle.width)), @as(f32, @floatFromInt(texture.handle.height)) },
        .animation => |animation| animation.getRegionFromAtlas(animation.frames[0]),
    };
    const origin: @Vector(2, f32) = switch (data.originStrategy) {
        .TopLeft => @Vector(2, f32){ 0, 0 },
        .TopRight => @Vector(2, f32){ 1, 0 },
        .BottomLeft => @Vector(2, f32){ 0, 1 },
        .BottomRight => @Vector(2, f32){ 1, 1 },
        .Centered => @Vector(2, f32){ 0.5, 0.5 },
    };
    return .{
        .source = data.source,
        .position = data.position,
        .size = data.size,
        .region = region,
        .origin = origin,
        .color = data.color,
    };
}

pub fn initFromAnimation(animation: *Animation, originStrategy: OriginStrategy) Sprite {
    const origin: @Vector(2, f32) = switch (originStrategy) {
        .TopLeft => @Vector(2, f32){ 0, 0 },
        .TopRight => @Vector(2, f32){ 1, 0 },
        .BottomLeft => @Vector(2, f32){ 0, 1 },
        .BottomRight => @Vector(2, f32){ 1, 1 },
        .Centered => @Vector(2, f32){ 0.5, 0.5 },
    };
    const region = animation.getRegionFromAtlas(animation.frames[0]);
    return .{
        .region = region,
        .origin = origin,
        .source = .{
            .animation = animation,
        },
    };
}

pub fn initFromTexture(texture: Texture, position: @Vector(2, f32), size: @Vector(2, f32), region: ?@Vector(4, f32)) Sprite {
    return .{
        .position = position,
        .size = size,
        .region = if (region) |r| r orelse .{
            0,
            0,
            @floatFromInt(texture.handle.width),
            @floatFromInt(texture.handle.height),
        },
        .source = .{
            .texture = texture,
        },
    };
}

pub fn initFromColor(color: @Vector(4, u8)) Sprite {
    return .{
        .region = .{ 0, 0, 1, 1 },
        .color = color,
        .source = .{
            .none = void{},
        },
    };
}
