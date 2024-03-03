const std = @import("std");
const glfw = @import("mach-glfw");
const Graphics = @import("AntleneOpenGL");
const zflecs = @import("zflecs");

pub const Application = @import("Application.zig");

pub const AntleneLogger = std.log.scoped(.Antlene);

fn glfwErrorCallback(error_code: glfw.ErrorCode, description: [:0]const u8) void {
    AntleneLogger.err("glfw: {}: {s}\n", .{ error_code, description });
}

fn loadProcAddresse(_: void, name: [:0]const u8) ?Graphics.glFunctionPointer {
    return glfw.getProcAddress(name);
}

pub fn entry() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    glfw.setErrorCallback(glfwErrorCallback);
    if (!glfw.init(.{})) {
        AntleneLogger.err("glfw: Failed to initialize: {?s}", .{glfw.getErrorString()});
        std.process.exit(0);
    }
    errdefer glfw.terminate();

    var application = try Application.init(allocator);
    errdefer {
        application.deinit();
        allocator.destroy(application);
    }

    try Graphics.init(allocator, loadProcAddresse);
    errdefer Graphics.deinit();

    while (!application.shouldClose()) {
        try application.update();
    }

    application.deinit();
    allocator.destroy(application);

    Graphics.deinit();
    glfw.terminate();
}
