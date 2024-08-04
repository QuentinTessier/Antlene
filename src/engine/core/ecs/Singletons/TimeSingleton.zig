const std = @import("std");
const ecs = @import("ecs");

const Pipeline = @import("../../Pipeline.zig");

pub const TimeSingleton = @This();

deltaTime: f32 = 0.0,
applicationTimer: std.time.Timer,

fps: f32 = 0.0,
offset: usize = 0,
fps_buffer: [100]f32 = [1]f32{0} ** 100,

pub fn init(_: std.mem.Allocator) TimeSingleton {
    return .{
        .applicationTimer = undefined,
    };
}

pub fn deinit(_: *TimeSingleton) void {}

pub fn setup(self: *TimeSingleton) !void {
    self.applicationTimer = try std.time.Timer.start();

    try Pipeline.register(.OnFrameStart, .{
        .callback = &OnFrameStart,
        .prio = 0,
    });
}

pub fn OnFrameStart(registry: *ecs.Registry) !void {
    var self = registry.singletons().get(TimeSingleton);

    const elapsed = self.applicationTimer.lap();
    self.deltaTime = @as(f32, @floatFromInt(elapsed)) / std.time.ns_per_s;
    if (self.offset < 100) {
        self.fps_buffer[self.offset] = self.deltaTime;
        self.offset += 1;
    } else {
        std.mem.copyBackwards(f32, self.fps_buffer[0..98], self.fps_buffer[1..99]);
        self.fps_buffer[99] = self.deltaTime;
    }
    var sum: f32 = 0;
    for (self.fps_buffer[0..self.offset]) |t| {
        sum += t;
    }
    const average_deltatime = sum / @as(f32, @floatFromInt(self.offset));
    self.fps = 1.0 / average_deltatime;
}
