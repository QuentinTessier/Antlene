const std = @import("std");
const ecs = @import("mach-ecs");
const Math = @import("AntleneMath");
const Context = @import("Context.zig");
const World = @import("../Engine.zig").World;
const Mesh = @import("Context.zig").Mesh;

pub const name = .mesh_pipeline;
const Module = World.Mod(@This());
pub const logger = std.log.scoped(name);

pub const components = struct {
    pub const transform = Math.mat4x4;
    pub const mesh_renderer = struct {
        pipeline: u8, // for future usage
    };
    pub const material = u32; // Change for a struture
};

const SceneData = extern struct {
    projection: Math.mat4x4 align(16),
    view: Math.mat4x4 align(16),
    viewPosition: @Vector(3, f32) align(16),
};

const MeshData = extern struct {
    ambient: Math.vec4 align(16),
    shininess: Math.vec4 align(16),
    model: Math.mat4x4 align(16),
    normal: Math.mat4x4 align(16), // Is a mat3x3 matrix stored in a mat4x4 for padding
};

const SceneUniformBuffer = Context.UniformBuffer(SceneData, 0);
const MeshUniformBuffer = Context.UniformBuffer(MeshData, 1);

program: Context.ShaderProgram.Program,
meshData: MeshUniformBuffer,
sceneData: SceneUniformBuffer,

pub fn init(world: *World) !void {
    const vertex_shader_source = @embedFile("shaders/mesh/vert.spv");
    const fragment_shader_source = @embedFile("shaders/mesh/frag.spv");

    const vertex = try Context.ShaderProgram.SPIRVShader(.vertex, .{}).initFromSource(vertex_shader_source);
    const fragment = try Context.ShaderProgram.SPIRVShader(.fragment, .{}).initFromSource(fragment_shader_source);

    const program = Context.ShaderProgram.Program.begin();
    vertex.attach(program);
    fragment.attach(program);
    try program.end();

    defer {
        vertex.deinit();
        fragment.deinit();
    }
    const state = &world.mod.mesh_pipeline.state;
    state.program = program;
    state.meshData = MeshUniformBuffer.init();
    state.sceneData = SceneUniformBuffer.init();
    state.sceneData.update(.{
        .projection = Math.perspective(Math.degreesToRadians(f32, 45.0), 1280.0 / 720.0, 0.1, 100.0),
        .view = Math.Mat4x4.identity(),
        .viewPosition = .{ 0, 0, 0 },
    });
    logger.info("Done initialization", .{});
}

pub fn deinit(world: *World) !void {
    const state = &world.mod.mesh_pipeline.state;
    state.program.deinit();
    state.meshData.deinit();
    state.sceneData.deinit();
    logger.info("Done deinitialization", .{});
}

pub const local = struct {
    pub fn prepareFrame(world: *World, renderer: *Module) !void {
        var q = world.entities.query(.{
            .all = &.{
                .{ .graphic_context = &.{.camera} },
            },
        });
        const sceneData: SceneUniformBuffer = renderer.state.sceneData;
        while (q.next()) |archetype| {
            const cameras: []Context.Camera = archetype.slice(.graphic_context, .camera);
            for (cameras) |cam| {
                if (cam.isActive) {
                    sceneData.updateMember(.view, cam.getViewMatrix());
                    sceneData.updateMember(.viewPosition, cam.position);
                    return;
                }
            }
        }
    }

    pub fn drawMeshes(world: *World, renderer: *Module) !void {
        var q = world.entities.query(.{
            .all = &.{
                .{ .graphic_context = &.{.mesh} },
                .{ .mesh_pipeline = &.{.transform} },
            },
        });
        const program: Context.ShaderProgram.Program = renderer.state.program;
        program.use();
        while (q.next()) |archetype| {
            const meshes: []Mesh = archetype.slice(.graphic_context, .mesh);
            const transform: []Math.mat4x4 = archetype.slice(.mesh_pipeline, .transform);

            for (meshes, 0..) |mesh, index| {
                internal_drawMesh(renderer, mesh, transform[index]);
            }
        }
    }
};

fn internal_drawMesh(self: *Module, mesh: Mesh, transform: Math.mat4x4) void {
    const meshData: MeshUniformBuffer = self.state.meshData;

    meshData.update(.{
        .ambient = Math.Vec4.init(.{ .x = 1, .y = 0, .z = 1, .w = 1 }),
        .shininess = Math.Vec4.splat(32.0),
        .model = transform,
        .normal = transform, // TODO: Inverse
    });

    mesh.draw();
}
