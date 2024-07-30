const std = @import("std");
const ecs = @import("ecs");
const Graphics = @import("AntleneOpenGL");

const Application = @import("../../../Application.zig");
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
    chunk: *EcsComponents.Chunk,
};

pub const Singletons = struct {
    application: **Application,
};

pub const PipelineStep: Pipeline.PipelineStep = .ReleaseResources;
pub const Priority: i32 = 0;

pub fn each(_: *ecs.Registry, _: ecs.Entity, components: Components, singletons: Singletons) !void {
    components.chunk.deinit(singletons.application.*.allocator);
}
