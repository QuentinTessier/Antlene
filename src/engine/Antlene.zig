const std = @import("std");
pub const ecs = @import("ecs");
const Graphics = @import("AntleneOpenGL");
const Window = @import("AntleneWindowSystem");
const Math = @import("AntleneMath");

pub const Application = @import("Application.zig");
pub const EventBus = @import("core/EventBus.zig");
pub const EnginePipeline = @import("core/Pipeline.zig");

pub const Components = @import("./core/ecs/Components.zig");

pub const ECS = @import("./core/ecs/ecs.zig");

pub fn entry(applicationCreateInfo: Application.ApplicationCreateInfo) !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    try EventBus.init(allocator);
    EnginePipeline.init(allocator);

    var application = try Application.init(allocator, applicationCreateInfo);
    errdefer {
        application.deinit() catch {};
        allocator.destroy(application);
    }

    try Graphics.init(allocator, struct {
        pub fn loadFn(_: void, name: [:0]const u8) ?Graphics.glFunctionPointer {
            return Window.getOpenGLProcAddr()(name);
        }
    }.loadFn);
    Graphics.resizeFramebuffer(application.window.extent.width, application.window.extent.height);

    try application.lateSetup();

    while (!application.shouldClose()) {
        try application.onFrameStart();
        try application.onPreFrameUpdate();
        try application.onFrameUpdate();
        try application.onFrameValidate();
        try application.onFrameEnd();
    }

    Graphics.deinit();
    try application.deinit();
    allocator.destroy(application);
    EnginePipeline.deinit();
    EventBus.deinit(allocator);
}
