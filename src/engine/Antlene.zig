const std = @import("std");
const zflecs = @import("zflecs");
const Graphics = @import("AntleneOpenGL");

const PlatfromWindow = @import("AntleneWindowSystem").PlatformWindow;
const Window = PlatfromWindow(Application);

pub const Application = @import("Application.zig");

pub var Allocator: std.mem.Allocator = undefined;
pub var ApplicationInstance: *Application = undefined;

pub const AntleneLogger = std.log.scoped(.Antlene);

fn loadProcAddr(_: void, name: [:0]const u8) ?Graphics.glFunctionPointer {
    return Window.getProcAddr()(name);
}

pub fn entry(applicationCreateInfo: Application.ApplicationCreateInfo) !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    Allocator = allocator;

    var application = try Application.init(allocator, applicationCreateInfo);
    errdefer {
        application.deinit();
        allocator.destroy(application);
    }
    ApplicationInstance = application;

    try Graphics.init(allocator, Window.glLoad);
    errdefer Graphics.deinit();
    Graphics.gl.depthRange(1.0, 0.0);
    Graphics.gl.clearColor(1.0, 0.0, 0.0, 1.0);

    while (!application.shouldClose()) {
        try application.update();
        Graphics.gl.clear(Graphics.gl.COLOR_BUFFER_BIT);

        application.finishFrame();
    }

    Graphics.deinit();
    application.deinit();
    allocator.destroy(application);
}
