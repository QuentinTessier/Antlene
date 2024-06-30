const std = @import("std");
const Window = @import("AntleneWindowSystem").PlatformWindow(Application);

pub const Application = @This();

pub const ApplicationCreateInfo = struct {
    name: [*:0]const u8,
    width: i32,
    height: i32,
};

window: Window,
isRunning: bool = true,

pub fn init(allocator: std.mem.Allocator, createInfo: ApplicationCreateInfo) !*Application {
    const app = try allocator.create(Application);
    app.* = Application{
        .window = try Window.create(.{
            .title = createInfo.name,
            .extent = .{ .x = 0, .y = 0, .width = createInfo.width, .height = createInfo.height },
            .context = .{ .OpenGL = .{ .major = 4, .minor = 6 } },
        }, app),
    };

    return app;
}

pub fn deinit(_: *Application) void {}

pub fn shouldClose(self: *Application) bool {
    return !self.isRunning;
}

pub fn update(self: *Application) !void {
    self.window.pollEvents();
}

pub fn finishFrame(self: *Application) void {
    self.window.swapBuffers();
}

pub fn draw(self: *Application) !void {
    _ = self;
}

pub fn onCloseEvent(self: *Application, _: *Window) void {
    self.isRunning = false;
}
