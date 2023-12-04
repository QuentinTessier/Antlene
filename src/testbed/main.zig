const std = @import("std");
const Antlene = @import("antlene");

pub const ApplicationParameters: Antlene.Application.Parameters = .{
    .name = "test",
    .version = 1,
    .init = &init,
    .windowInfo = .{
        .name = "test",
        .width = 1280,
        .height = 720,
    },
};

pub fn init(app: *Antlene.Application) anyerror!void {
    _ = try app.sceneManager.createScene(GUIScene, "GUIScene", app.allocator);
}

pub const GUIScene = struct {
    base: Antlene.SceneManager.Scene,

    pub fn init(self: *GUIScene) void {
        std.log.info("Init scene !", .{});
        _ = self;
    }

    pub fn onCreate(base: *Antlene.SceneManager.Scene, allocator: std.mem.Allocator) anyerror!void {
        _ = allocator;
        const s = base.newSprite(.{ 10, 10 }, .{ 100, 100 });
        const s1 = base.newSprite(.{ 120, 10 }, .{ 100, 100 });
        _ = s1;
        _ = s;
    }
};
