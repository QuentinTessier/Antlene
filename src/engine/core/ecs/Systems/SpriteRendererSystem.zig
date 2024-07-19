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

pub const Singletons = struct {
    textureRegistry: *TextureRegistry,
    renderer: *RendererFrontEnd.Renderer2D,
};

pub const PipelineStep: Pipeline.PipelineStep = .OnFrameValidate;
pub const Priority: i32 = 100;

pub fn begin(_: *ecs.Registry, singletons: Singletons) void {
    singletons.renderer.begin();
}

pub fn end(_: *ecs.Registry, singletons: Singletons) void {
    singletons.renderer.end();
}

pub fn each(_: *ecs.Registry, _: ecs.Entity, components: Components, singletons: Singletons) !void {
    const texRegistry = singletons.textureRegistry;
    var renderer = singletons.renderer;

    const texture: ?Graphics.Texture = if (components.sprite.handle) |handle| texRegistry.texturePool.getColumnIfLive(handle, .texture) else null;
    renderer.drawIsometricSprite(components.transform, components.sprite.region, texture, components.sprite.color);
}
