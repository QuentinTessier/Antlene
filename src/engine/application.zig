pub const std = @import("std");

const gl = @import("core/Platform/gl/gl.zig");

const Window = @import("./core/Platform/Window.zig").Window;
const WindowEvent = @import("./core/Platform/Window.zig").WindowEvent;
const GlobalEventBus = @import("./core/GlobalEventBus.zig");

const Graphics = @import("./core/Graphics.zig");
const Camera = @import("./core/Camera.zig").Camera;
const Renderer2D = @import("core/Graphics/Renderer2D.zig");

pub const Application = struct {
    name: [*:0]const u8,
    version: u32,
    allocator: std.mem.Allocator,

    running: bool = true,
    window: *Window,
    update: *const fn (*Application, deltaTime: f64) anyerror!void,

    userData: ?*anyopaque = null,

    mainCamera: Camera = Camera{ .position = .{ 0.0, 0.0 } },

    pub fn init(allocator: std.mem.Allocator, appInfo: ApplicationInformation) !Application {
        var window: *Window = try allocator.create(Window);
        window.* = Window.init(appInfo.name, 1000, 800);
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

        try Renderer2D.init(allocator);

        return .{
            .name = appInfo.name,
            .version = appInfo.version,
            .allocator = allocator,
            .window = window,
            .update = appInfo.gameUpdate,
        };
    }

    pub fn deinit(self: *Application, allocator: std.mem.Allocator) void {
        allocator.destroy(self.window);
        Renderer2D.deinit(self.allocator);
        gl.Types.deinit();
    }

    pub fn run(self: *Application) anyerror!void {
        var timer = try std.time.Timer.start();
        var aggregate: f64 = 0.0;

        Graphics.setClearColor(.{ 0.0, 0.0, 0.0, 1.0 });
        try GlobalEventBus.listen(WindowEvent, self, &Application.onWindowEvent);

        const currentExtent = self.window.getWindowExtent();
        self.mainCamera.width = @as(f32, @floatFromInt(currentExtent.width));
        self.mainCamera.height = @as(f32, @floatFromInt(currentExtent.height));
        self.mainCamera.buildProjection();

        while (self.running) {
            const elapsed = @as(f64, @floatFromInt(timer.lap())) / @as(f64, std.time.ns_per_s);
            aggregate += elapsed;
            try self.window.pollEvents();

            Graphics.clear();

            try self.update(self, elapsed);

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
    gameUpdate: *const fn (*Application, deltaTime: f64) anyerror!void,
};
