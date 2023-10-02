pub const std = @import("std");

const gl = @import("core/Platform/gl/gl.zig");

const Window = @import("./core/Platform/Window.zig").Window;
const WindowEvent = @import("./core/Platform/Window.zig").WindowEvent;
const GlobalEventBus = @import("core/GlobalEventBus.zig");

pub const Application = struct {
    name: [*:0]const u8,
    version: u32,

    running: bool = true,
    window: *Window,

    pub fn init(allocator: std.mem.Allocator, name: [*:0]const u8, version: u32) !Application {
        var window: *Window = try allocator.create(Window);
        window.* = Window.init(name, 800, 600);
        _ = try window.create();

        try GlobalEventBus.register(WindowEvent);

        _ = try gl.initContext(window.getDC(), 4, 6);
        try gl.loadGL();

        if (std.debug.runtime_safety) {
            gl.enable(gl.DEBUG_OUTPUT);
            gl.debugMessageCallback(gl.messageCallback, null);
        }

        gl.enable(gl.BLEND);
        gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);

        return .{ .name = name, .version = version, .window = window };
    }

    pub fn deinit(self: *Application, allocator: std.mem.Allocator) void {
        allocator.destroy(self.window);
    }

    pub fn run(self: *Application) anyerror!void {
        try GlobalEventBus.listen(WindowEvent, self, &Application.onWindowEvent);
        while (self.running) {
            try self.window.pollEvents();
            self.window.swapBuffers();
        }
    }

    pub fn onWindowEvent(self: *Application, window: ?*anyopaque, event: WindowEvent) void {
        _ = window;
        switch (event) {
            .close => {
                std.log.info("Closing Application", .{});
                self.running = false;
            },
            else => {},
        }
    }

    pub fn getGraphicAPIVersion(self: *Application) [*:0]const u8 {
        _ = self;
        return gl.getString(gl.VERSION);
    }
};

pub const ApplicationInformation = struct {
    name: [*:0]const u8,
    version: u32,
    gameInit: *const fn (*Application) anyerror!void,
};
