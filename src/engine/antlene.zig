const std = @import("std");
const zstbi = @import("zstbi");

pub const Application = @import("application.zig").Application;
pub const ApplicationInformation = @import("application.zig").ApplicationInformation;
pub const Version = @import("Version.zig").Version;

pub const Camera = @import("core/Camera.zig").Camera;

pub const GlobalEventBus = @import("core/GlobalEventBus.zig");
pub const Renderer2D = @import("core/Graphics/Renderer2D.zig");

pub const GameState = @import("core/GameState.zig");
pub const SceneBase = @import("core/Scene.zig").SceneBase;

pub var ApplicationHandle: *Application = undefined;

pub fn entry(appInfo: ApplicationInformation) anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();
    ApplicationHandle = try allocator.create(Application);
    defer allocator.destroy(ApplicationHandle);

    zstbi.init(allocator);
    defer zstbi.deinit();

    try GlobalEventBus.init(allocator);
    defer GlobalEventBus.deinit(allocator);

    ApplicationHandle.* = try Application.init(allocator, appInfo);
    try appInfo.gameInit(ApplicationHandle);

    try ApplicationHandle.run();

    ApplicationHandle.deinit(allocator);
}
