const std = @import("std");
const Graphics = @import("AntleneOpenGL");
const Math = @import("AntleneMath");
const ECS = @import("../ecs/ecs.zig");

const Sprite = ECS.Components.Sprite;
const Transform = ECS.Components.Transform;

pub const IsometricRenderer = @This();

pub const VertexPerQuad = 4;
pub const IndexPerQuad = 6;
pub const MaximunNumberOfSprites = 20000;
pub const MaximunNumberOfVertices = VertexPerQuad * MaximunNumberOfSprites;
pub const MaximunNumberOfIndices = IndexPerQuad * MaximunNumberOfSprites;

pub const Vertex = extern struct {
    position: [4]f32,
    uv: [2]f32,
};

pipeline: Graphics.GraphicPipeline,
vertexBuffer: Graphics.Buffer,
indexBuffer: Graphics.Buffer,

vertices: []Vertex,
currentVertex: usize = 0,
currentIndex: usize = 0,

defaultSampler: Graphics.Sampler,

firstPass: bool = true,

pub fn init(allocator: std.mem.Allocator) !IsometricRenderer {
    const vertexSource = try Graphics.Shader.loadFile(allocator, .glsl, "./assets/Shaders/isometric/isometric.vert");
    defer allocator.free(vertexSource);
    const fragmentSource = try Graphics.Shader.loadFile(allocator, .glsl, "./assets/Shaders/isometric/isometric.frag");
    defer allocator.free(fragmentSource);

    const pipeline = try Graphics.Resources.CreateGraphicPipeline(.{
        .name = "IsometricRenderer",
        .vertexShaderSource = .{ .glsl = vertexSource },
        .fragmentShaderSource = .{ .glsl = fragmentSource },
        .vertexInputState = .{
            .vertexAttributeDescription = &.{},
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

    const vertexBuffer = Graphics.Resources.CreateTypedBuffer("IsometricRenderer_Vertices", Vertex, .{ .count = MaximunNumberOfVertices }, .{ .dynamic = true });
    const vertices = try allocator.alloc(Vertex, MaximunNumberOfVertices);
    Graphics.Commands.BindStorageBuffer(1, vertexBuffer, .whole, .{});

    var indices: [MaximunNumberOfIndices]u32 = undefined;
    var i: usize = 0;
    var offset: u32 = 0;
    while (i < MaximunNumberOfIndices) : (i += 6) {
        indices[i + 0] = offset + 0;
        indices[i + 1] = offset + 1;
        indices[i + 2] = offset + 2;

        indices[i + 3] = offset + 2;
        indices[i + 4] = offset + 3;
        indices[i + 5] = offset + 0;

        offset += 4;
    }
    const indexBuffer = Graphics.Resources.CreateBuffer("IsometricRenderer_Indices", .{ .ptr = std.mem.sliceAsBytes(&indices) }, .{});

    const defaultSampler = Graphics.Resources.CreateSampler(.{
        .minFilter = .nearest,
        .magFilter = .nearest,
        .wrapR = .repeat,
        .wrapS = .repeat,
        .wrapT = .repeat,
    });

    Graphics.Commands.BindGraphicPipeline(pipeline);
    const loc = Graphics.gl.getUniformLocation(pipeline.handle, "u_Tileset");
    _ = Graphics.gl.uniform1i(loc, 0);
    return .{
        .pipeline = pipeline,
        .vertexBuffer = vertexBuffer,
        .indexBuffer = indexBuffer,
        .vertices = vertices,
        .defaultSampler = defaultSampler,
    };
}

pub fn deinit(self: *IsometricRenderer, allocator: std.mem.Allocator) void {
    self.vertexBuffer.deinit();
    self.indexBuffer.deinit();
    self.pipeline.deinit(allocator);
    allocator.free(self.vertices);
}

pub fn execute(self: IsometricRenderer) !void {
    Graphics.Commands.BindIndexBuffer(self.indexBuffer, .u32);
    Graphics.Commands.DrawElements(@intCast(self.currentIndex), 1, 0, 0, 0);
}

pub fn batch(self: *IsometricRenderer) !void {
    self.vertexBuffer.updateData(std.mem.sliceAsBytes(self.vertices[0..self.currentVertex]), 0);
    try Graphics.Rendering.toSwapchain(.{
        .colorLoadOp = if (self.firstPass) .clear else .keep,
        .depthLoadOp = if (self.firstPass) .clear else .keep,
        .clearDepthValue = 1.0,
        .viewport = .{},
    }, self.*);
}

pub fn flush(self: *IsometricRenderer) void {
    self.currentIndex = 0;
    self.currentVertex = 0;
}

pub fn drawSprite(self: *IsometricRenderer, transform: Transform, region: @Vector(4, f32)) bool {
    if (self.currentVertex >= MaximunNumberOfVertices) return false;
    const textureCoords = [4]@Vector(2, f32){
        .{ 1.0, 1.0 },
        .{ 0.0, 1.0 },
        .{ 0.0, 0.0 },
        .{ 1.0, 0.0 },
    };

    const positions = [4]@Vector(4, f32){
        .{ 0.0, 0.0, 0.0, 1.0 },
        .{ 1.0, 0.0, 0.0, 1.0 },
        .{ 1.0, 1.0, 0.0, 1.0 },
        .{ 0.0, 1.0, 0.0, 1.0 },
    };

    for (self.vertices[self.currentVertex .. self.currentVertex + 4], 0..) |*vertex, index| {
        const model = transform.getMatrix();
        const position = Math.Mat4x4.mulVec(model, .{ positions[index][0], positions[index][1], positions[index][2], 1.0 });
        const uvOffset: @Vector(2, f32) = .{ region[0], region[1] };
        const uvScale: @Vector(2, f32) = .{ region[2], region[3] };

        vertex.* = Vertex{
            .position = position,
            .uv = textureCoords[index] * uvScale + uvOffset,
        };
    }
    self.currentVertex += 4;
    self.currentIndex += 6;
    return true;
}
