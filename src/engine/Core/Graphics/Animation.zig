const std = @import("std");
const Atlas = @import("Atlas.zig").Atlas;
const Sprite = @import("Sprite.zig");

pub const Animation = @This();

atlas: *Atlas,

frames: []usize,
currentFrame: usize = 0,

frameDelay: f32,
currentDelay: f32 = 0.0,

paused: bool = false,
loop: bool = true,

pub fn isDone(self: *const Animation) bool {
    return self.currentFrame >= self.frames.len - 1;
}

pub fn getRegionFromAtlas(self: *const Animation, index: ?usize) @Vector(4, f32) {
    return self.atlas.regions.items[self.frames[if (index) |i| i else self.currentFrame]];
}

pub fn update(self: *Animation, deltaTime: f32) ?@Vector(4, f32) {
    if (self.paused) return null;
    self.currentDelay += deltaTime;
    if (self.currentDelay >= self.frameDelay) {
        self.currentDelay = 0.0;
        if (self.isDone()) {
            if (self.loop) {
                self.currentFrame = 0;
            } else {
                return null;
            }
        } else {
            self.currentFrame += 1;
        }
        return self.getRegionFromAtlas(null);
    }
    return null;
}

pub fn reset(self: *Animation) void {
    self.currentFrame = 0;
    self.currentDelay = 0.0;
}

pub fn pause(self: *Animation) void {
    self.paused = !self.paused;
}
