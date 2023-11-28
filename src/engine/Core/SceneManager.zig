const std = @import("std");
const ecs = @import("zflecs");
pub const Scene = @import("Scene.zig").Scene;

pub const SceneManager = @This();

scenes: std.StringHashMapUnmanaged(*Scene) = .{},
currentScene: ?*Scene = null,
previousScene: ?*Scene = null,

pub fn createScene(self: *SceneManager, comptime T: type, name: []const u8, allocator: std.mem.Allocator) !*T {
    Scene.EnsureTypeDefinition(T);
    var scene = try Scene.createScene(T, name, allocator);
    try self.scenes.put(allocator, name, &scene.base);
    if (scene.base.onCreate) |onCreate| {
        try onCreate(&scene.base, allocator);
    }

    if (self.currentScene == null) {
        self.currentScene = &scene.base;
    }

    return scene;
}

pub fn deinit(self: *SceneManager, allocator: std.mem.Allocator) void {
    var ite = self.scenes.iterator();
    while (ite.next()) |item| {
        if (item.value_ptr.*.onDestroy) |onDestroy| {
            onDestroy(item.value_ptr.*, allocator) catch {};
        }
        item.value_ptr.*.deinit(allocator);
    }
    self.scenes.deinit(allocator);
}

pub fn findScene(self: *SceneManager, name: []const u8) ?*Scene {
    return self.scenes.get(name);
}

pub fn switchScene(self: *SceneManager, name: []const u8) bool {
    if (self.findScene(name)) |scene| {
        self.previousScene = self.currentScene;
        self.currentScene = scene;
        return true;
    }
    return false;
}

pub fn drawScene(self: *SceneManager) void {
    if (self.currentScene) |currentScene| {
        if (currentScene.onDraw) |onDraw| {
            onDraw(currentScene);
            currentScene.draw();
        }
    }
}

pub fn updateScene(self: *SceneManager, deltaTime: f32) void {
    if (self.currentScene) |currentScene| {
        _ = ecs.progress(currentScene.world, deltaTime);
        if (currentScene.onUpdate) |onUpdate| {
            onUpdate(currentScene, deltaTime);
        }
    }
}
