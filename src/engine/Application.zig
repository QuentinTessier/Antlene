const std = @import("std");
const glfw = @import("mach-glfw");
const gl = @import("gl");

const AntleneLogger = std.log.scoped(.Antlene);

pub const Application = @This();
const GraphicsContext = @import("core/graphics/Context.zig");

allocator: std.mem.Allocator,
window: glfw.Window,

context: GraphicsContext,

fn glGetProcAddress(_: void, proc: [:0]const u8) ?gl.FunctionPointer {
    return glfw.getProcAddress(proc);
}

pub fn init(allocator: std.mem.Allocator, title: [*:0]const u8, width: u32, height: u32) !Application {
    var self: Application = undefined;
    self.allocator = allocator;
    self.window = glfw.Window.create(width, height, title, null, null, .{
        .opengl_profile = .opengl_core_profile,
        .context_version_major = 4,
        .context_version_minor = 6,
    }) orelse {
        AntleneLogger.err("glfw: Failed to initialize window: {?s}", .{glfw.getErrorString()});
        return error.FailedToInitializeWindow;
    };
    glfw.makeContextCurrent(self.window);

    try gl.load(void{}, glGetProcAddress);

    self.context = try GraphicsContext.init();

    AntleneLogger.info("Application: Initialization done !", .{});
    return self;
}

pub fn deinit(self: *Application) void {
    self.context.deinit();
    self.window.destroy();
    AntleneLogger.info("Application: Destruction successful", .{});
}

const vertices = [_]GraphicsContext.Mesh.Vertex{
    .{ .position = .{ 0.5, 0.5, 0.0 }, .normal = .{ 0, 0, 0 }, .texCoords = .{ 0, 0 } },
    .{ .position = .{ 0.5, -0.5, 0.0 }, .normal = .{ 0, 0, 0 }, .texCoords = .{ 0, 0 } },
    .{ .position = .{ -0.5, -0.5, 0.0 }, .normal = .{ 0, 0, 0 }, .texCoords = .{ 0, 0 } },
    .{ .position = .{ -0.5, 0.5, 0.0 }, .normal = .{ 0, 0, 0 }, .texCoords = .{ 0, 0 } },
};

const indices = [_]u32{ 0, 1, 3, 1, 2, 3 };

pub fn run(self: *Application) !void {
    gl.clearColor(0, 0, 0, 1);
    var mesh = GraphicsContext.Mesh.init(&vertices, &indices);
    defer mesh.deinit();
    while (!self.window.shouldClose()) {
        glfw.pollEvents();

        gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

        self.context.draw(mesh);

        self.window.swapBuffers();
    }
}
