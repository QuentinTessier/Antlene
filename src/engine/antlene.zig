const std = @import("std");

pub const Application = @import("application.zig").Application;
pub const ApplicationInformation = @import("application.zig").ApplicationInformation;
pub const Version = @import("Version.zig").Version;

pub const GlobalEventBus = @import("core/GlobalEventBus.zig");

pub var ApplicationHandle: *Application = undefined;

pub fn entry(appInfo: ApplicationInformation) anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();
    ApplicationHandle = try allocator.create(Application);
    defer allocator.destroy(ApplicationHandle);

    try GlobalEventBus.init(allocator);
    defer GlobalEventBus.deinit(allocator);

    ApplicationHandle.* = try Application.init(allocator, appInfo.name, appInfo.version);
    try appInfo.gameInit(ApplicationHandle);

    try ApplicationHandle.run();

    ApplicationHandle.deinit(allocator);
}
