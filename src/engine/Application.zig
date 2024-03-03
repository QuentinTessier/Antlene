const std = @import("std");
const glfw = @import("mach-glfw");
const zflecs = @import("zflecs");

pub const Application = @This();

window: glfw.Window,
world: *zflecs.world_t,

pub fn init(allocator: std.mem.Allocator) !*Application {
    const app = try allocator.create(Application);
    app.* = Application{
        .window = glfw.Window.create(1280, 720, "Antlene Application", null, null, .{
            .opengl_profile = .opengl_core_profile,
            .context_version_major = 4,
            .context_version_minor = 6,
        }) orelse {
            std.log.err("failed to create GLFW window: {?s}", .{glfw.getErrorString()});
            return error.FailedToInitWindow;
        },
        .world = zflecs.init(),
    };
    glfw.makeContextCurrent(app.window);

    return app;
}

pub fn deinit(self: *Application) void {
    _ = zflecs.fini(self.world);
    self.window.destroy();
}

pub fn shouldClose(self: *Application) bool {
    return self.window.shouldClose();
}

pub fn update(self: *Application) !void {
    _ = self;
    glfw.pollEvents();
}

pub fn draw(self: *Application) !void {
    _ = self;
}
