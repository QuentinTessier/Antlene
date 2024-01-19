const std = @import("std");
const glfw = @import("mach-glfw");
const gl = @import("gl");
const ecs = @import("mach-ecs");


const World = @import("Engine.zig").World;

pub const Application = @This();

world: World,

pub fn init(allocator: std.mem.Allocator) !Application {
    var app = Application{
        .world = try World.init(allocator),
    };
    try app.world.send(.engine, .init, .{});
    return app;
}

pub fn deinit(self: *Application) !void {
    try self.world.send(.engine, .deinit, .{});
}

pub fn update(self: *Application) !bool {
    try self.world.send(.engine, .tick, .{});
    return self.world.mod.engine.state.isRunning;
}
