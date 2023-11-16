const std = @import("std");
const Texture = @import("./Graphics/Texture.zig");
const Sprite = @import("./Graphics/Sprite.zig");

pub const SceneBase = struct {
    name: []const u8,

    // Methods
    onUpdate: ?*const fn (*SceneBase, f64) anyerror!void,
    onDraw: ?*const fn (*SceneBase) void,

    textures: std.StringHashMapUnmanaged(Texture),
    sprites: std.StringArrayHashMapUnmanaged(Sprite),

    internal_free: *const fn (*SceneBase, std.mem.Allocator) void,
};

pub const SceneManager = struct {
    currentScene: ?*SceneBase = null,
    previousScene: ?*SceneBase = null,

    scenes: std.StringHashMapUnmanaged(*SceneBase) = .{},

    pub fn deinit(self: *SceneManager, allocator: std.mem.Allocator) void {
        var ite = self.scenes.iterator();
        while (ite.next()) |item| {
            var scene = item.value_ptr.*;
            scene.internal_free(scene, allocator);
        }
    }

    pub fn registerScene(self: *SceneManager, allocator: std.mem.Allocator, comptime T: type, name: []const u8) !*SceneBase {
        comptime {
            if (!@hasField(T, "base") || std.meta.fieldInfo(T, std.meta.FieldEnum(T).base).type != SceneBase) {
                @panic("Trying to add a Scene without a base or of wrong time, use the antlene interface to create a Scene");
            }
        }

        var scene = try allocator.create(T);
        if (@hasDecl(T, "init")) {
            scene = try T.init(allocator);
        }
        scene.base = .{
            .name = name,
            .internal_free = struct {
                fn free(base: *SceneBase, a: std.mem.Allocator) void {
                    var parent = @fieldParentPtr(T, "base", base);
                    base.textures.deinit(a);
                    base.sprites.deinit(a);
                    a.free(parent);
                }
            }.free,
            .onUpdate = if (@hasDecl(T, "onUpdate")) &T.onUpdate else null,
            .onDraw = if (@hasDecl(T, "onDraw")) &T.onDraw else null,
            .textures = .{},
            .sprites = .{},
        };

        try self.scenes.put(allocator, name, &scene.base);
        return &scene.base;
    }

    pub fn unregisterScene(self: *SceneManager, name: []const u8) ?*SceneBase {
        const value = self.scenes.get(name);
        self.scenes.remove(name);
        return value;
    }

    pub fn doesSceneExist(self: *SceneManager, name: []const u8) bool {
        return self.scenes.contains(name);
    }

    pub fn getScene(self: *SceneManager, name: []const u8) ?*SceneBase {
        return self.scenes.get(name);
    }

    pub fn switchScene(self: *SceneManager, name: []const u8) bool {
        var new = self.getScene(name);
        if (new) |s| {
            self.previousScene = self.currentScene;
            self.currentScene = s;
        } else {
            return false;
        }
    }

    pub fn updateScene(self: *SceneManager, deltaTime: f64) anyerror!void {
        if (self.currentScene) |current| {
            if (current.onUpdate) |update| {
                try update(current, deltaTime);
            }
        }
    }

    pub fn drawScene(self: *SceneManager) void {
        if (self.currentScene) |current| {
            if (current.onDraw) |draw| {
                draw(current);
            }
        }
    }
};
