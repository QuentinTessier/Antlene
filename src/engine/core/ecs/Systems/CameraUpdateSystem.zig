const std = @import("std");
const ecs = @import("ecs");
const Graphics = @import("AntleneOpenGL");
const Pipeline = @import("../../Pipeline.zig");

const RendererFrontEnd = @import("../../RendererFrontend.zig");

const EcsComponents = @import("../Components.zig");
const Application = @import("../../../Application.zig");

// TODO: Have a better way to query screen size without getting a pointer to the whole Application
// TODO: Have the system check if the screen size changed
pub const CameraUpdateSystemDescription = @This();

pub const Name = "CameraUpdateSystem";

pub const Includes = .{
    EcsComponents.Camera,
    EcsComponents.ActiveCamera,
};

pub const Excludes = .{};

pub const Components = struct {
    camera: *EcsComponents.Camera,
};

pub const Singletons = struct {
    application: **Application,
};

pub const PipelineStep: Pipeline.PipelineStep = .OnFrameValidate;
pub const Priority: i32 = 0;

pub fn each(_: *ecs.Registry, _: ecs.Entity, components: Components, singletons: Singletons) !void {
    const cameraMatrix = components.camera.getViewProjection(
        @floatFromInt(singletons.application.*.window.extent.width),
        @floatFromInt(singletons.application.*.window.extent.height),
    );

    RendererFrontEnd.updateSceneCamera(cameraMatrix);
}
