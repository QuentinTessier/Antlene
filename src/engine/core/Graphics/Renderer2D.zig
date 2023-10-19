const std = @import("std");
const gl = @import("../Platform/gl/gl.zig");
const zm = @import("zmath");
const zstbi = @import("zstbi");

// OpenGL Abstraction
const Texture = @import("Texture.zig");
const Shader = @import("Shader.zig");
const Buffer = @import("Buffer.zig");
const VertexArray = @import("VertexArray.zig");
const UniformBuffer = @import("UniformBuffer.zig").TypedUniformBuffer;

pub const Sprite = @import("Sprite.zig");

const Camera = @import("../Camera.zig").Camera;

const qBatcher = struct {
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

    program: u32,
    vbo: Buffer,
    ebo: Buffer,
    vao: VertexArray,

    vertices: []Vertex,
    currentVertex: usize = 0,
    currentIndex: usize = 0,
};

const Context = struct {
    pub const TextureCount = 16;
    pub const CameraUniformBuffer = UniformBuffer(struct { projectionMatrix: zm.Mat });

    qBatcher: qBatcher,
    whiteTexture: Texture,
    textures: [TextureCount]u32 = [1]u32{0} ** 16,
    currentTexture: usize = 1,
    cameraUniformBuffer: CameraUniformBuffer,
};

var context: Context = undefined;

pub fn init(allocator: std.mem.Allocator) !void {
    const stages = [2][]const u8{
        "resources/shaders/spriteBatch.vert",
        "resources/shaders/spriteBatch.frag",
    };
    const layout = comptime VertexArray.layoutFromType(qBatcher.Vertex);
    context.qBatcher.program = try Shader.loadProgram(allocator, &stages);
    context.qBatcher.vbo = Buffer.createEmpty(.Array, .DymanicDraw, @sizeOf(qBatcher.Vertex) * qBatcher.MaximunNumberOfVertices);
    context.qBatcher.vao = VertexArray.create();
    context.qBatcher.vao.bind();
    context.qBatcher.vao.setAttribPointers(layout);

    var indices: [qBatcher.MaximunNumberOfIndices]i32 = undefined;
    var i: usize = 0;
    var offset: i32 = 0;
    while (i < qBatcher.MaximunNumberOfIndices) : (i += 6) {
        indices[i + 0] = offset + 0;
        indices[i + 1] = offset + 1;
        indices[i + 2] = offset + 2;

        indices[i + 3] = offset + 2;
        indices[i + 4] = offset + 3;
        indices[i + 5] = offset + 0;

        offset += 4;
    }
    context.qBatcher.ebo = Buffer.create(i32, &indices, .Element, .StaticDraw);
    context.qBatcher.vertices = try allocator.alloc(qBatcher.Vertex, qBatcher.MaximunNumberOfVertices);

    const location = Shader.getUniformLocation(context.qBatcher.program, "u_Textures");
    const textures: [16]i32 = .{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15 };
    gl.useProgram(context.qBatcher.program);
    gl.uniform1iv(location, 16, (&textures).ptr);
    gl.useProgram(0);

    var img = try zstbi.Image.loadFromFile("resources/images/white.png", 3);
    context.whiteTexture = Texture.createFromImage(&img, true);
    img.deinit();
    context.textures[0] = context.whiteTexture.handle;

    const defaultMatrix = zm.identity();
    context.cameraUniformBuffer = Context.CameraUniformBuffer.init(.{ .projectionMatrix = defaultMatrix });
    gl.bindBufferBase(gl.UNIFORM_BUFFER, 0, context.cameraUniformBuffer.handle);
}

pub fn deinit(allocator: std.mem.Allocator) void {
    allocator.free(context.qBatcher.vertices);
    context.qBatcher.vao.destroy();
    context.qBatcher.vbo.destroy();
    context.qBatcher.ebo.destroy();
    gl.deleteProgram(context.qBatcher.program);
}

pub inline fn begin(camera: Camera) void {
    context.cameraUniformBuffer.updateMember(.projectionMatrix, camera.projection);
    beginBatch();
}

pub inline fn end() void {
    endBatch();
}

inline fn beginBatch() void {
    context.qBatcher.currentVertex = 0;
    context.qBatcher.currentIndex = 0;
    context.currentTexture = 1;
}

inline fn endBatch() void {
    flush();
}

fn flush() void {
    gl.useProgram(context.qBatcher.program);
    if (context.qBatcher.currentVertex > 0) {
        context.qBatcher.vbo.updateData(qBatcher.Vertex, context.qBatcher.vertices[0..context.qBatcher.currentVertex], 0);
        for (context.textures[0..context.currentTexture], 0..) |texture, index| {
            const textureIndex = gl.TEXTURE0 + index;
            gl.activeTexture(@intCast(textureIndex));
            gl.bindTexture(gl.TEXTURE_2D, texture);
        }

        context.qBatcher.vao.bind();
        context.qBatcher.ebo.bind();
        gl.drawElements(gl.TRIANGLES, @intCast(context.qBatcher.currentIndex), gl.UNSIGNED_INT, null);
    }
}

inline fn nextBatch() void {
    flush();
    beginBatch();
}

pub fn drawColoredQuad(position: @Vector(2, f32), size: @Vector(2, f32), rotation: f32, color: @Vector(4, f32), tilingFactor: f32) void {
    const textureIndex = 0.0;
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
    if (context.qBatcher.currentVertex >= qBatcher.MaximunNumberOfVertices)
        nextBatch();

    var transform = zm.identity();
    transform = zm.mul(transform, zm.translation(position[0], position[1], 0.0));
    transform = zm.mul(transform, zm.translation(size[0] * 0.5, size[1] * 0.5, 0.0));
    transform = zm.mul(transform, zm.rotationZ(std.math.degreesToRadians(f32, rotation)));
    transform = zm.mul(transform, zm.translation(size[0] * -0.5, size[1] * -0.5, 0.0));
    transform = zm.mul(transform, zm.scaling(size[0], size[1], 1.0));
    for (context.qBatcher.vertices[context.qBatcher.currentVertex .. context.qBatcher.currentVertex + 4], 0..) |*vertex, index| {
        const pos = zm.mul(transform, @Vector(4, f32){ positions[index][0], positions[index][1], 0.0, 1.0 });
        vertex.* = .{
            .position = [2]f32{ pos[0], pos[1] },
            .texCoords = textureCoords[index],
            .color = color,
            .tilingFactor = tilingFactor,
            .texIndex = textureIndex,
        };
    }
    context.qBatcher.currentVertex += 4;
    context.qBatcher.currentIndex += 6;
}

pub fn drawTexturedQuad(position: @Vector(2, f32), size: @Vector(2, f32), rotation: f32, color: @Vector(4, f32), texture: Texture, tilingFactor: f32) void {
    var textureIndex: f32 = 0.0;
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
    if (context.qBatcher.currentVertex >= qBatcher.MaximunNumberOfVertices)
        nextBatch();

    for (context.textures[1..context.currentTexture], 1..) |tex, index| {
        if (texture.handle == tex) {
            textureIndex = @floatFromInt(index);
            break;
        }
    }
    if (textureIndex == 0.0) {
        if (context.currentTexture >= Context.TextureCount)
            nextBatch();
        textureIndex = @floatFromInt(context.currentTexture);
        context.textures[context.currentTexture] = texture.handle;
        context.currentTexture += 1;
    }

    var transform = zm.identity();
    transform = zm.mul(transform, zm.translation(position[0], position[1], 0.0));
    transform = zm.mul(transform, zm.translation(size[0] * 0.5, size[1] * 0.5, 0.0));
    transform = zm.mul(transform, zm.rotationZ(std.math.degreesToRadians(f32, rotation)));
    transform = zm.mul(transform, zm.translation(size[0] * -0.5, size[1] * -0.5, 0.0));
    transform = zm.mul(transform, zm.scaling(size[0], size[1], 1.0));
    for (context.qBatcher.vertices[context.qBatcher.currentVertex .. context.qBatcher.currentVertex + 4], 0..) |*vertex, index| {
        const pos = zm.mul(transform, @Vector(4, f32){ positions[index][0], positions[index][1], 0.0, 1.0 });
        vertex.* = .{
            .position = [2]f32{ pos[0], pos[1] },
            .texCoords = textureCoords[index],
            .color = color,
            .tilingFactor = tilingFactor,
            .texIndex = textureIndex,
        };
    }
    context.qBatcher.currentVertex += 4;
    context.qBatcher.currentIndex += 6;
}

pub fn drawSprite(sprite: Sprite) void {
    if (sprite.texture) |texture| {
        drawTexturedQuad(sprite.position, sprite.size, sprite.rotation, sprite.color, texture, 1.0);
    } else {
        drawColoredQuad(sprite.position, sprite.size, sprite.rotation, sprite.color, 1.0);
    }
}
