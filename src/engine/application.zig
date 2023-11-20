pub const std = @import("std");

const Window = @import("./core/Platform/Window.zig").Window;
const CloseEvent = @import("./core/Platform/Window.zig").CloseEvent;
const GlobalEventBus = @import("./core/GlobalEventBus.zig");

const Graphics = @import("./core/Graphics.zig");
const Camera = @import("./core/Camera.zig").Camera;
//const Renderer2D = @import("core/Graphics/Renderer2D.zig");

const SceneManager = @import("core/SceneManager.zig").SceneManager;
const SceneBase = @import("core/SceneManager.zig").SceneBase;

pub const Application = struct {
    name: [*:0]const u8,
    version: u32,
    allocator: std.mem.Allocator,

    running: bool = true,
    window: *Window,

    sceneManager: SceneManager = .{},

    mainCamera: Camera = Camera{ .position = .{ 0.0, 0.0 } },

    pub fn init(allocator: std.mem.Allocator, appInfo: ApplicationInformation) !Application {
        var window: *Window = try allocator.create(Window);
        window.* = Window.init(appInfo.name, 1000, 800, GlobalEventBus.getPtr());
        window.create();

        Graphics.loadGraphics(Window.getProcAdrr());

        // TODO: Register new Window Event types
        try GlobalEventBus.register(CloseEvent);

        // TODO: Update the way the context is created (maybe inside AntleneWindowSystem directly)
        //_ = try gl.initContext(@ptrCast(window.dc), 4, 6);
        //try gl.loadGL();

        //if (std.debug.runtime_safety) {
        //    gl.enable(gl.DEBUG_OUTPUT);
        //    gl.debugMessageCallback(gl.messageCallback, null);
        //}

        //gl.enable(gl.BLEND);
        //gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);

        //try Renderer2D.init(allocator);

        return .{
            .name = appInfo.name,
            .version = appInfo.version,
            .allocator = allocator,
            .window = window,
        };
    }

    pub fn deinit(self: *Application, allocator: std.mem.Allocator) void {
        allocator.destroy(self.window);
        self.sceneManager.deinit(allocator);
        //Renderer2D.deinit(self.allocator);
        //gl.Types.deinit();
    }

    pub fn run(self: *Application) anyerror!void {
        var timer = try std.time.Timer.start();
        var aggregate: f64 = 0.0;

        try GlobalEventBus.listen(CloseEvent, self, &Application.onCloseEvent);

        //Graphics.setClearColor(.{ 0.0, 0.0, 0.0, 1.0 });
        //try GlobalEventBus.listen(WindowEvent, self, &Application.onWindowEvent);

        const currentExtent = self.window.extent;
        self.mainCamera.width = @as(f32, @floatFromInt(currentExtent.width));
        self.mainCamera.height = @as(f32, @floatFromInt(currentExtent.height));
        self.mainCamera.buildProjection();

        while (self.running) {
            const elapsed = @as(f64, @floatFromInt(timer.lap())) / @as(f64, std.time.ns_per_s);
            aggregate += elapsed;
            self.window.pollEvents();

            //Graphics.clear();

            try self.sceneManager.updateScene(elapsed);
            self.sceneManager.drawScene();

            //self.window.swapBuffers();
        }
    }

    pub fn onCloseEvent(self: *Application, _: ?*anyopaque, _: CloseEvent) void {
        self.running = false;
    }

    pub fn registerScene(self: *Application, comptime T: type, name: []const u8) !*SceneBase {
        return self.sceneManager.registerScene(self.allocator, T, name);
    }

    pub fn updateScene(self: *Application) anyerror!void {
        try self.sceneManager.updateScene();
    }
};

pub const ApplicationInformation = struct {
    name: [*:0]const u8,
    version: u32,
    gameInit: *const fn (*Application) anyerror!void,
};
