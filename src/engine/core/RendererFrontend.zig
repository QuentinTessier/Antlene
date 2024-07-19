const std = @import("std");
const Graphics = @import("AntleneOpenGL");
const Math = @import("AntleneMath");

const Sprite = @import("Graphics/Sprite.zig");

pub const Renderer = @This();

pub const Renderer2D = struct {
    pub const VertexPerQuad = 4;
    pub const IndexPerQuad = 6;
    pub const MaximunNumberOfSprites = 20000;
    pub const MaximunNumberOfVertices = VertexPerQuad * MaximunNumberOfSprites;
    pub const MaximunNumberOfIndices = IndexPerQuad * MaximunNumberOfSprites;
    pub const Vertex = struct {
        position: [2]f32,
        texCoords: [2]f32,
        color: [4]f32,
        tilingFactor: f32,
        texIndex: f32,
    };

    pipeline: Graphics.GraphicPipeline,
    vertexBuffer: Graphics.Buffer,
    indexBuffer: Graphics.Buffer,

    vertices: []Vertex,
    currentVertex: usize = 0,
    currentIndex: usize = 0,

    whiteTexture: Graphics.Texture = undefined,
    textures: [16]Graphics.Texture = undefined,
    currentTexture: usize = 1,

    isFirstPassForFrame: bool = true,

    pub fn init(allocator: std.mem.Allocator) !Renderer2D {
        const vertexSource = try Graphics.Shader.loadFile(allocator, .glsl, "./assets/Shaders/sprite.vert");
        defer allocator.free(vertexSource);
        const fragmentSource = try Graphics.Shader.loadFile(allocator, .glsl, "./assets/Shaders/sprite.frag");
        defer allocator.free(fragmentSource);

        const pipeline = try Graphics.Resources.CreateGraphicPipeline(.{
            .name = "Renderer2D",
            .vertexShaderSource = .{ .glsl = vertexSource },
            .fragmentShaderSource = .{ .glsl = fragmentSource },
            .vertexInputState = .{
                .vertexAttributeDescription = &.{},
            },
        });

        const vertexBuffer = Graphics.Resources.CreateTypedBuffer("Renderer2D_Vertices", Vertex, .{ .count = MaximunNumberOfVertices }, .{ .dynamic = true });
        const vertices = try allocator.alloc(Vertex, MaximunNumberOfVertices);

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
        const indexBuffer = Graphics.Resources.CreateBuffer("Renderer2D_Indices", .{ .ptr = std.mem.sliceAsBytes(&indices) }, .{});

        const whiteTexture = Graphics.Resources.CreateTexture(.{
            .name = "Renderer2D_WhiteTexture",
            .type = ._2D,
            .format = .rgba8,
            .extent = .{ .width = 1, .height = 1, .depth = 0 },
            .mipLevels = 1,
        });
        const pixel = [4]u8{ 255, 255, 255, 255 };
        whiteTexture.update(.{
            .extent = .{ .width = 1, .height = 1, .depth = 0 },
            .format = .rgba,
            .type = .u8,
            .data = &pixel,
        });

        const textures: [16]i32 = .{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15 };
        Graphics.gl.useProgram(pipeline.handle);
        const loc = Graphics.gl.getUniformLocation(pipeline.handle, "u_Textures");
        Graphics.gl.uniform1iv(loc, 16, (&textures).ptr);
        Graphics.gl.useProgram(0);

        return .{
            .pipeline = pipeline,
            .vertexBuffer = vertexBuffer,
            .indexBuffer = indexBuffer,
            .vertices = vertices,
            .whiteTexture = whiteTexture,
            .textures = [1]Graphics.Texture{whiteTexture} ++ [1]Graphics.Texture{undefined} ** 15,
        };
    }

    pub fn deinit(self: *Renderer2D, allocator: std.mem.Allocator) void {
        self.vertexBuffer.deinit();
        self.indexBuffer.deinit();
        self.whiteTexture.deinit();
        self.pipeline.deinit(allocator);
        allocator.free(self.vertices);
    }

    pub fn begin(self: *Renderer2D) void {
        self.currentVertex = 0;
        self.currentIndex = 0;
        self.currentTexture = 1;
        self.isFirstPassForFrame = true;
    }

    pub fn end(self: *Renderer2D) void {
        self.flush();
    }

    pub fn execute(self: *const Renderer2D) !void {
        Graphics.Commands.BindGraphicPipeline(self.pipeline);
        for (self.textures[0..self.currentTexture], 0..) |texture, index| {
            Graphics.Commands.BindTexture(@intCast(index), texture);
        }
        Graphics.Commands.BindIndexBuffer(self.indexBuffer, .u32);
        Graphics.Commands.BindStorageBuffer(1, self.vertexBuffer, .whole, .{});
        Graphics.Commands.DrawElements(@intCast(self.currentIndex), 1, 0, 0, 0);
    }

    pub fn flush(self: *Renderer2D) void {
        self.vertexBuffer.updateData(std.mem.sliceAsBytes(self.vertices[0..self.currentVertex]), 0);
        Graphics.Rendering.toSwapchain(
            .{
                .colorLoadOp = .keep, //if (self.isFirstPassForFrame) .clear else .keep,
                .viewport = .{},
            },
            self,
        ) catch {
            std.log.err("Failed to render to swapchain", .{});
        };
    }

    pub fn drawSprite(self: *Renderer2D, sprite: Sprite) void {
        if (self.currentVertex >= MaximunNumberOfVertices) {
            self.flush();
            self.currentIndex = 0;
            self.currentVertex = 0;
            self.currentTexture = 1;
        }

        const textureCoords = [4]@Vector(2, f32){
            .{ 0.0, 0.0 },
            .{ 1.0, 0.0 },
            .{ 1.0, 1.0 },
            .{ 0.0, 1.0 },
        };

        const positions = [4]@Vector(4, f32){
            .{ -0.5, -0.5, 0.0, 1.0 },
            .{ 0.5, -0.5, 0.0, 1.0 },
            .{ 0.5, 0.5, 0.0, 1.0 },
            .{ -0.5, 0.5, 0.0, 1.0 },
        };

        if (self.currentTexture >= 16) {
            self.flush();
            self.currentIndex = 0;
            self.currentVertex = 0;
            self.currentTexture = 1;
        }

        const textureIndex: f32 = blk: {
            if (sprite.texture) |sTexture| {
                for (self.textures[1..self.currentTexture], 0..) |texture, index| {
                    if (texture.handle == sTexture.handle) {
                        break :blk @as(f32, @floatFromInt(index));
                    }
                }
                self.textures[self.currentTexture] = sTexture;
                const index = self.currentTexture;
                self.currentTexture += 1;
                break :blk @as(f32, @floatFromInt(index));
            } else {
                break :blk 0.0;
            }
        };

        for (self.vertices[self.currentVertex .. self.currentVertex + 4], 0..) |*vertex, index| {
            const model = sprite.getTransform();
            const position = Math.Mat4x4.mulVec(model, .{ positions[index][0], positions[index][1], 0.0, 1.0 });
            const uvOffset: @Vector(2, f32) = .{ sprite.region[0], sprite.region[1] };
            const uvScale: @Vector(2, f32) = .{ sprite.region[2], sprite.region[3] };

            vertex.* = Vertex{
                .position = .{ position[0], position[1] },
                .texCoords = textureCoords[index] * uvScale + uvOffset,
                .color = sprite.color,
                .tilingFactor = 1.0,
                .texIndex = textureIndex,
            };
        }
        self.currentVertex += 4;
        self.currentIndex += 6;
    }
};