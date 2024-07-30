const std = @import("std");
const ecs = @import("ecs");
const Graphics = @import("AntleneOpenGL");
const Pipeline = @import("../../Pipeline.zig");

const TextureRegistry = @import("../Singletons/TextureRegistry.zig");
const RendererFrontEnd = @import("../../RendererFrontend.zig");

const EcsComponents = @import("../Components.zig");

pub const SpriteRendererSystemDescription = @This();

pub const Name = "SpriteRendererSystem";

pub const Includes = .{
    EcsComponents.Transform,
    EcsComponents.Sprite,
};

pub const Excludes = .{};

pub const Components = struct {
    transform: EcsComponents.Transform,
    sprite: EcsComponents.Sprite,
};

pub const Singletons = void;

pub const PipelineStep: Pipeline.PipelineStep = .OnFrameValidate;
pub const Priority: i32 = 100;

pub fn begin(_: *ecs.Registry, _: Singletons) void {
    RendererFrontEnd.isometricRenderer.firstPass = true;
}

pub fn end(_: *ecs.Registry, _: Singletons) void {
    RendererFrontEnd.isometricRenderer.batch() catch {};
    RendererFrontEnd.isometricRenderer.flush();
    RendererFrontEnd.isometricRenderer.firstPass = false;
}

pub fn each(_: *ecs.Registry, _: ecs.Entity, components: Components, _: Singletons) !void {
    if (!RendererFrontEnd.isometricRenderer.drawSprite(components.transform, components.sprite.region)) {
        try RendererFrontEnd.isometricRenderer.batch();
        RendererFrontEnd.isometricRenderer.flush();
        _ = RendererFrontEnd.isometricRenderer.drawSprite(components.transform, components.sprite.region);
    }
}
