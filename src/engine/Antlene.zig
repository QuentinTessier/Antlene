const std = @import("std");
const glfw = @import("mach-glfw");

pub const Application = @import("Application.zig");

pub const AntleneLogger = std.log.scoped(.Antlene);

fn glfwErrorCallback(error_code: glfw.ErrorCode, description: [:0]const u8) void {
    AntleneLogger.err("glfw: {}: {s}\n", .{ error_code, description });
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
    defer glfw.terminate();

    var application = try Application.init(allocator);

    while (try application.update()) {
        try application.draw();
    }

    try application.deinit();
}
