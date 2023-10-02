const std = @import("std");

pub const Application = @import("application.zig").Application;
pub const ApplicationInformation = @import("application.zig").ApplicationInformation;
pub const Version = @import("Version.zig").Version;

pub const GlobalEventBus = @import("core/GlobalEventBus.zig");

pub fn entry(appInfo: ApplicationInformation) anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();
    var app = try allocator.create(Application);
    defer allocator.destroy(app);

    try GlobalEventBus.init(allocator);
    defer GlobalEventBus.deinit(allocator);

    app.* = Application.init(appInfo.name, appInfo.version);
    try appInfo.gameInit(app);
}
