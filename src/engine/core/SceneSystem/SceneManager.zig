const std = @import("std");
pub const Scene = @import("Scene.zig");

pub const SceneManager = @This();

scenes: std.StringHashMapUnmanaged(*Scene) = .{},
currentScene: ?*Scene = null,

pub fn registerScene(comptime SceneWrapper: type, name: []const u8) !bool {
    if (!@hasField(SceneWrapper, "base")) @panic("SceneWrapper should have a field named base with type Scene");
}
