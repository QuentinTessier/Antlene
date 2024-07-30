const std = @import("std");
const ecs = @import("ecs");
const Graphics = @import("AntleneOpenGL");
const Pipeline = @import("../../Pipeline.zig");

const TextureRegistry = @import("../Singletons/TextureRegistry.zig");
const RendererFrontEnd = @import("../../RendererFrontend.zig");
const EcsComponents = @import("../Components.zig");

pub const ChunkRendererSystemDescription = @This();

pub const Name = "ChunkRendererSystem";

pub const Includes = .{
    EcsComponents.Chunk,
};

pub const Excludes = .{};

pub const Components = struct {
    chunk: *const EcsComponents.Chunk,
};

pub const Singletons = void;

pub const PipelineStep: Pipeline.PipelineStep = .OnFrameValidate;
pub const Priority: i32 = 50;

pub fn each(_: *ecs.Registry, _: ecs.Entity, components: Components, _: Singletons) !void {
    try RendererFrontEnd.chunkRenderer.draw(components.chunk);
}
