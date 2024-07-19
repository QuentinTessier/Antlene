const std = @import("std");
const ecs = @import("ecs");
const Events = @import("AntleneWindowSystem").Events;
const Window = @import("AntleneWindowSystem").PlatformWindow(Application);
const Graphics = @import("AntleneOpenGL");
const Pipeline = @import("./core/Pipeline.zig");

const EventBus = @import("core/EventBus.zig");

pub const Application = @This();

pub const ApplicationCreateInfo = struct {
    name: [*:0]const u8,
    width: i32,
    height: i32,

    initialize: *const fn (*Application) anyerror!void,
};

const Singletons = @import("./core/ecs/Singletons.zig");
const System = @import("./core/ecs/System.zig");

window: Window,
allocator: std.mem.Allocator,
isRunning: bool = true,
registry: ecs.Registry,

pub fn init(allocator: std.mem.Allocator, createInfo: ApplicationCreateInfo) !*Application {
    const app = try allocator.create(Application);
    app.* = Application{
        .allocator = allocator,
        .window = try Window.create(.{
            .title = createInfo.name,
            .extent = .{ .x = 0, .y = 0, .width = createInfo.width, .height = createInfo.height },
            .context = .{ .OpenGL = .{ .major = 4, .minor = 6 } },
        }, app),
        .registry = ecs.Registry.init(allocator),
    };

    app.registry.singletons().add(app);
    try Singletons.registerDefaultSingletons(&app.registry, app.allocator);
    try System.registerSystem(System.MakeSystem(System.KeyEventLogicSystemDescription));

    try createInfo.initialize(app);

    return app;
}

pub fn deinit(self: *Application) !void {
    self.registry.deinit();
}

pub fn shouldClose(self: *Application) bool {
    return !self.isRunning;
}

pub fn close(self: *Application) void {
    self.isRunning = false;
}

pub fn onFrameStart(self: *Application) !void {
    self.window.pollEvents();

    try Pipeline.exec(&self.registry, .OnFrameStart);
}

pub fn onPreFrameUpdate(self: *Application) !void {
    EventBus.process();
    try Pipeline.exec(&self.registry, .OnPreFrameUpdate);
}

pub fn onFrameUpdate(self: *Application) !void {
    try Pipeline.exec(&self.registry, .OnFrameUpdate);
}

pub fn onFrameValidate(self: *Application) !void {
    try Pipeline.exec(&self.registry, .OnFrameValidate);
}

pub fn onFrameEnd(self: *Application) !void {
    try Pipeline.exec(&self.registry, .OnFrameEnd);
    self.window.swapBuffers();
}

pub fn onCloseEvent(self: *Application, _: *Window) void {
    self.isRunning = false;
}

pub fn onKeyEvent(_: *Application, _: *Window, e: Events.KeyEvent) void {
    EventBus.postpone(e) catch {
        std.log.err("Failed to push event {} to Application EventBus", .{e});
        return;
    };
}

pub fn onWindowResizeEvent(_: *Application, _: *Window, _: Events.ResizeEvent) void {}
