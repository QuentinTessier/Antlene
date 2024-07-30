const std = @import("std");
pub const ecs = @import("ecs");
pub const Graphics = @import("AntleneOpenGL");
const Window = @import("AntleneWindowSystem");
pub const Math = @import("AntleneMath");

pub const Memory = @import("core/Memory.zig");
pub const Application = @import("Application.zig");
pub const EventBus = @import("core/EventBus.zig");
pub const EnginePipeline = @import("core/Pipeline.zig");

pub const Components = @import("./core/ecs/Components.zig");

pub const ECS = @import("./core/ecs/ecs.zig");

pub const Noise = @import("znoise");

pub fn entry(applicationCreateInfo: Application.ApplicationCreateInfo) !void {
    Memory.init();
    try EventBus.init();
    EnginePipeline.init();

    var application = try Application.init(Memory.Allocator, applicationCreateInfo);
    errdefer {
        application.deinit() catch {};
        Memory.Allocator.destroy(application);
    }

    while (!application.shouldClose()) {
        try application.onFrameStart();
        try application.onPreFrameUpdate();
        try application.onFrameUpdate();
        try application.onFrameValidate();
        try application.onFrameEnd();
    }

    try application.onReleaseRessources();

    Graphics.deinit();
    try application.deinit();
    Memory.Allocator.destroy(application);
    EnginePipeline.deinit();
    EventBus.deinit();
    Memory.deinit();
}
