const std = @import("std");
const glfw = @import("mach-glfw");
const gl = @import("gl");
const ecs = @import("mach-ecs");

const World = @import("Engine.zig").World;

// TMP
const Math = @import("AntleneMath");
const Mesh = @import("graphics/Context.zig");
const Camera = @import("graphics/Camera.zig").FlyingCamera;

pub const Application = @This();

world: World,

pub fn init(allocator: std.mem.Allocator) !Application {
    var app = Application{
        .world = try World.init(allocator),
    };
    try app.world.send(.engine, .init, .{});

    const p = try app.world.entities.new();
    try app.world.entities.setComponent(p, .graphic_context, .mesh, Mesh.Cube());
    try app.world.entities.setComponent(p, .mesh_pipeline, .transform, Math.Mat4x4.identity());

    const c = try app.world.entities.new();
    try app.world.entities.setComponent(c, .graphic_context, .camera, Camera.init(.{ 0, 0, 3 }, .{ 0, 1, 0 }, .{ 0, 0, -1 }, -90.0, 0.0));

    return app;
}

pub fn deinit(self: *Application) !void {
    try self.world.send(.engine, .deinit, .{});
}

pub fn update(self: *Application) !bool {
    try self.world.send(.engine, .tick, .{});
    return self.world.mod.engine.state.isRunning;
}

pub fn draw(self: *Application) !void {
    try self.world.send(.engine, .draw, .{});
    try self.world.send(.engine, .present, .{});
}
