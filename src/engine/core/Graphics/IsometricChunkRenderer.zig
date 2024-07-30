const std = @import("std");
const Graphics = @import("AntleneOpenGL");
const Math = @import("AntleneMath");
const ECS = @import("../ecs/ecs.zig");

pub const Chunk = @import("../ecs/Components/Chunk.zig");
const Tile = Chunk.Tile;

pub const IsometricChunkRenderer = @This();

pipeline: Graphics.GraphicPipeline,
indices: Graphics.Buffer,
vertices: Graphics.Buffer,

firstPass: bool = true,

const Vertex = struct {
    uv: [2]f32,
};

pub fn init(allocator: std.mem.Allocator) !IsometricChunkRenderer {
    const vertexSource = try Graphics.Shader.loadFile(allocator, .glsl, "./assets/Shaders/isometric/tilemap/tilemap.vert");
    defer allocator.free(vertexSource);
    const fragmentSource = try Graphics.Shader.loadFile(allocator, .glsl, "./assets/Shaders/isometric/isometric.frag");
    defer allocator.free(fragmentSource);

    const pipeline = try Graphics.Resources.CreateGraphicPipeline(.{
        .name = "IsometricRenderer",
        .vertexShaderSource = .{ .glsl = vertexSource },
        .fragmentShaderSource = .{ .glsl = fragmentSource },
        .vertexInputState = .{
            .vertexAttributeDescription = &.{.{
                .location = 0,
                .binding = 3,
                .format = .f32,
                .size = 2,
                .offset = 0,
            }},
        },
        .colorBlendState = .{
            .attachments = &.{
                .{
                    .blendEnable = true,
                    .srcRgbFactor = .SrcAlpha,
                    .dstRgbFactor = .OneMinusSrcAlpha,
                    .srcAlphaFactor = .One,
                    .dstAlphaFactor = .Zero,
                },
            },
        },
        .depthState = .{
            .depthWriteEnable = true,
            .depthCompareOp = .less,
            .depthTestEnable = true,
        },
    });

    var indices: [6]u16 = .{ 0, 1, 2, 2, 3, 0 };
    const indexBuffer = Graphics.Resources.CreateBuffer(
        "IsometricRenderer_Indices",
        .{ .ptr = std.mem.sliceAsBytes(&indices) },
        .{},
    );

    const vertices = [8]f32{
        0.0, 1.0,
        1.0, 1.0,
        1.0, 0.0,
        0.0, 0.0,
    };
    var vertexBuffer = Graphics.Resources.CreateBuffer(
        "TilemapRenderer_Vertices",
        .{ .ptr = std.mem.sliceAsBytes(&vertices) },
        .{},
    );
    vertexBuffer.stride = @sizeOf(f32) * 2;
    return .{
        .pipeline = pipeline,
        .indices = indexBuffer,
        .vertices = vertexBuffer,
    };
}

pub fn deinit(self: *IsometricChunkRenderer, allocator: std.mem.Allocator) void {
    self.pipeline.deinit(allocator);
}

pub fn draw(self: *IsometricChunkRenderer, chunk: *const Chunk) !void {
    if (chunk.gpuBuffer == null) return;

    const Pass = struct {
        pipeline: Graphics.GraphicPipeline,
        vertices: Graphics.Buffer,
        indices: Graphics.Buffer,
        instances: Graphics.Buffer,
        nInstances: u32,

        pub fn execute(s: @This()) !void {
            Graphics.Commands.BindGraphicPipeline(s.pipeline);
            Graphics.Commands.BindVertexBuffer(3, s.vertices, 0);
            Graphics.Commands.BindIndexBuffer(s.indices, .u16);
            Graphics.Commands.BindStorageBuffer(2, s.instances, .whole, .{});

            Graphics.Commands.DrawElements(6, s.nInstances, 0, 0, 0);
        }
    };

    try Graphics.Rendering.toSwapchain(.{
        .viewport = .{},
    }, Pass{
        .pipeline = self.pipeline,
        .vertices = self.vertices,
        .indices = self.indices,
        .instances = chunk.gpuBuffer.?,
        .nInstances = @intCast(chunk.tiles.items.len),
    });
}
