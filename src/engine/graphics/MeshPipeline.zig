const std = @import("std");
const ecs = @import("mach-ecs");
const gl = @import("gl");
const Math = @import("AntleneMath");
const Context = @import("Context.zig").GraphicContext;
const World = @import("../core/Engine.zig").World;
const Mesh = @import("Context.zig").GraphicContext.Mesh;
const Material = @import("gl/Material.zig");

pub const name = .mesh_pipeline;
const Module = World.Mod(@This());
pub const logger = std.log.scoped(name);

pub const components = struct {
    pub const transform = Math.mat4x4;
    pub const mesh_renderer = struct {
        pipeline: u8, // for future usage
    };
    pub const material = Material; // Change for a struture
};

const MeshData = extern struct {
    model: Math.mat4x4 align(16),
    shininess: f32 align(4),
    tilingFactor: f32 align(4),
};

const MeshUniformBuffer = Context.UniformBuffer(MeshData, 1);

program: Context.ShaderProgram.Program,
meshData: MeshUniformBuffer,
//sceneData: SceneUniformBuffer, // TODO: This should be handled by the graphic_context and it should define prepareFrame

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
    logger.info("Done initialization", .{});
}

pub fn deinit(world: *World) !void {
    const state = &world.mod.mesh_pipeline.state;
    state.program.deinit();
    state.meshData.deinit();
    logger.info("Done deinitialization", .{});
}

pub const local = struct {
    pub fn drawMeshes(world: *World, renderer: *Module) !void {
        var q = world.entities.query(.{
            .all = &.{
                .{ .graphic_context = &.{.mesh} },
                .{ .mesh_pipeline = &.{ .transform, .material } },
            },
        });
        const program: Context.ShaderProgram.Program = renderer.state.program;
        program.use();
        while (q.next()) |archetype| {
            const meshes: []Mesh = archetype.slice(.graphic_context, .mesh);
            const transform: []Math.mat4x4 = archetype.slice(.mesh_pipeline, .transform);
            const materials: []Material = archetype.slice(.mesh_pipeline, .material);

            for (meshes, 0..) |mesh, index| {
                internal_drawMesh(renderer, mesh, transform[index], materials[index]);
            }
        }
    }
};

fn internal_drawMesh(self: *Module, mesh: Mesh, transform: Math.mat4x4, material: Material) void {
    const meshData: MeshUniformBuffer = self.state.meshData;

    meshData.update(.{
        .shininess = material.shininess,
        .model = transform,
        .tilingFactor = material.tilingFactor,
    });
    gl.bindTextures(0, 3, @ptrCast(&.{
        material.diffuse.handle,
        material.specular.handle,
        material.normal.handle,
    }));
    mesh.draw();
}
