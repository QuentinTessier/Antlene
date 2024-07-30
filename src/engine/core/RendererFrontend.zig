const std = @import("std");
const Graphics = @import("AntleneOpenGL");
const Math = @import("AntleneMath");
const ecs = @import("ecs");
const TextureRegistry = @import("./ecs/Singletons/TextureRegistry.zig");

const IsometricRenderer = @import("./Graphics/IsometricRenderer.zig");
const IsometricChunkRenderer = @import("./Graphics/IsometricChunkRenderer.zig");

pub const Renderer = @This();

// TODO: Give access to the sub-renderers without declaring the variable has public
pub var isometricRenderer: IsometricRenderer = undefined;
pub var chunkRenderer: IsometricChunkRenderer = undefined;
var sceneUniformBuffer: Graphics.Buffer = undefined;
var tileset: TextureRegistry.TextureHandle = undefined;

const SceneData = extern struct {
    projection: Math.mat4x4,
    isometric: Math.mat4x4,
    orientation: Math.mat4x4,
};

pub fn init(allocator: std.mem.Allocator, registry: *ecs.Registry) !void {
    const data = SceneData{
        .projection = Math.Mat4x4.identity(),
        .isometric = Math.Mat4x4.init(.{
            .{ 16.0, -16.0, 0.0, 0.0 },
            .{ 8.0, 8.0, 0.0, 0.0 },
            .{ 0.0, 0.0, 1.0, 0.0 },
            .{ 0.0, 0.0, 0.0, 1.0 },
        }),
        .orientation = Math.Mat4x4.identity(),
    };

    isometricRenderer = try IsometricRenderer.init(allocator);
    chunkRenderer = try IsometricChunkRenderer.init(allocator);
    sceneUniformBuffer = Graphics.Resources.CreateBuffer(
        "Global_SceneData",
        .{ .ptr = std.mem.asBytes(&data) },
        .{ .dynamic = true },
    );
    Graphics.Commands.BindUniformBuffer(0, sceneUniformBuffer, .whole, .{});

    var textureRegistry = registry.singletons().get(TextureRegistry);
    tileset = try textureRegistry.loadTexture(allocator, "assets/isometric-sandbox-sheet.png", null);

    const texture = try textureRegistry.texturePool.getColumn(tileset, .texture);

    Graphics.Commands.BindSampledTexture(0, texture, isometricRenderer.defaultSampler);
}

pub fn deinit(allocator: std.mem.Allocator) void {
    isometricRenderer.deinit(allocator);
    chunkRenderer.deinit(allocator);
}

pub fn updateSceneCamera(vp: Math.mat4x4) void {
    sceneUniformBuffer.updateData(std.mem.asBytes(&vp), 0);
}

pub fn updateIsometricMatrix(iso: Math.mat4x4) void {
    sceneUniformBuffer.updateData(std.mem.asBytes(&iso), @sizeOf(Math.mat4x4));
}

pub fn updateOritentation(m: Math.mat4x4) void {
    sceneUniformBuffer.updateData(std.mem.asBytes(&m), @sizeOf(Math.mat4x4) * 2);
}
