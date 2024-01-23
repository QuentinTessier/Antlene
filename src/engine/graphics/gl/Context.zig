const std = @import("std");
const gl = @import("gl");
const Math = @import("AntleneMath");

const World = @import("../../core/Engine.zig").World;
pub const Camera = @import("../Camera.zig").FlyingCamera;
const glGetProcAddress = @import("../../core/Engine.zig").glGetProcAddress;

pub const GenericMesh = @import("Mesh.zig").Mesh;
pub const DefaultVertex = @import("Mesh.zig").DefaultVertexNormal;
pub const Mesh = GenericMesh(DefaultVertex);
pub const Cube = @import("Mesh.zig").cube;
pub const Plane = @import("Mesh.zig").plane;
pub const Sphere = @import("Mesh.zig").sphere;

pub const Texture = @import("Texture.zig");
pub const ShaderProgram = @import("Shader.zig");

pub const UniformBuffer = @import("UniformBuffer.zig").UniformBuffer;

pub const OpenGLContext = @This();
pub const name = .graphic_context;
const Module = World.Mod(OpenGLContext);
const logger = std.log.scoped(name);

// TODO: Entity should be able to refer the same mesh, this is not implemented yet in mach-ecs
pub const components = struct {
    pub const mesh = Mesh;
    pub const camera = Camera;
    pub const active = bool;
};

const SceneData = extern struct {
    projection: Math.mat4x4 align(16),
    view: Math.mat4x4 align(16),
    viewPosition: @Vector(3, f32) align(16),
};

sceneData: UniformBuffer(SceneData, 0),

pub fn init(world: *World, context: *Module) !void {
    _ = context; // autofix
    try gl.load(void{}, glGetProcAddress);

    world.mod.graphic_context.state.sceneData = UniformBuffer(SceneData, 0).init();
    world.mod.graphic_context.state.sceneData.update(.{
        .projection = Math.Mat4x4.identity(),
        .view = Math.Mat4x4.identity(),
        .viewPosition = Math.Vec3.init(.{ .x = 0, .y = 0, .z = 0 }),
    });
}

pub fn deinit(world: *World) !void {
    var q = world.entities.query(.{
        .all = &.{
            .{ .graphic_context = &.{.mesh} },
        },
    });
    while (q.next()) |archetype| {
        const meshes: []Mesh = archetype.slice(.graphic_context, .mesh);
        for (meshes) |*mesh| {
            mesh.deinit();
        }
    }
    world.mod.graphic_context.state.sceneData.deinit();
}

pub fn prepareFrame(world: *World) !void {
    gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
    var q = world.entities.query(.{
        .all = &.{
            .{ .graphic_context = &.{ .camera, .active } },
        },
    });
    while (q.next()) |archetype| {
        const cameras: []Camera = archetype.slice(.graphic_context, .camera);
        for (cameras) |*cam| {
            if (cam.isDirty) {
                cam.updateVectors();
                cam.isDirty = false;
            }
            world.mod.graphic_context.state.sceneData.update(.{
                .projection = cam.getProjectionMatrix(),
                .view = cam.getViewMatrix(),
                .viewPosition = cam.position,
            });
        }
    }
}

pub const local = struct {
    pub fn setClearColor(_: *World, color: @Vector(4, f32)) !void {
        gl.clearColor(color[0], color[1], color[2], color[3]);
    }

    pub fn clearScreen(_: *World) !void {
        gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
    }

    pub fn resize(world: *World, width: u32, height: u32) !void {
        gl.viewport(0, 0, @intCast(width), @intCast(height));
        const fWidth: f32 = @floatFromInt(width);
        const fHeight: f32 = @floatFromInt(height);
        var q = world.entities.query(.{
            .all = &.{
                .{ .graphic_context = &.{.camera} },
            },
        });
        while (q.next()) |archetype| {
            const cameras: []Camera = archetype.slice(.graphic_context, .camera);
            for (cameras) |*cam| {
                cam.aspect_ratio = fWidth / fHeight;
                cam.isDirty = true;
            }
        }
    }
};
