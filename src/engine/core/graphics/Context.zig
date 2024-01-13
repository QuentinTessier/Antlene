const std = @import("std");
const gl = @import("gl");
const ShaderProgram = @import("gl/Shader.zig");
const UniformBuffer = @import("gl/UniformBuffer.zig").UniformBuffer;
const Math = @import("../math/root.zig");

pub const Mesh = @import("gl/Mesh.zig").Mesh(@import("gl/Mesh.zig").DefaultVertex);

const AntleneLogger = std.log.scoped(.Antlene);

pub const Context = @This();

const CameraUniformBufferData = struct {
    projection: Math.mat4x4,
    view: Math.mat4x4,
};

const MeshUniformBufferData = struct {
    model: Math.mat4x4,
    color: Math.vec4,
    normal: Math.mat3x3,
};

defaultProgram: ShaderProgram.Program,
cameraUBO: UniformBuffer(CameraUniformBufferData, 0),
meshDataUBO: UniformBuffer(MeshUniformBufferData, 1),

pub fn init() !Context {
    AntleneLogger.info("GraphicContext: Finished initialization", .{});

    const vertex = try ShaderProgram.Shader.initFromSource(@embedFile("./gl/shaders/mesh.vs"), .vertex);
    const fragment = try ShaderProgram.Shader.initFromSource(@embedFile("./gl/shaders/mesh.fs"), .fragment);
    defer {
        vertex.deinit();
        fragment.deinit();
    }

    const defaultProgram = ShaderProgram.Program.begin();

    vertex.attach(defaultProgram);
    fragment.attach(defaultProgram);

    try defaultProgram.end();

    const cameraUBO = UniformBuffer(CameraUniformBufferData, 0).init();
    const meshDataUBO = UniformBuffer(MeshUniformBufferData, 1).init();
    cameraUBO.update(.{
        .projection = Math.Mat4x4.identity(),
        .view = Math.Mat4x4.identity(),
    });
    meshDataUBO.update(.{
        .model = Math.Mat4x4.translate(.{ 0.1, 0.0, 0.0 }),
        .color = .{ 1, 0, 0, 1 },
        .normal = Math.Mat3x3.identity(),
    });
    return .{
        .defaultProgram = defaultProgram,
        .cameraUBO = cameraUBO,
        .meshDataUBO = meshDataUBO,
    };
}

pub fn deinit(self: *Context) void {
    self.defaultProgram.deinit();
    self.cameraUBO.deinit();
    self.meshDataUBO.deinit();
}

pub fn draw(self: *Context, mesh: Mesh) void {
    self.defaultProgram.use();
    mesh.draw();
}
