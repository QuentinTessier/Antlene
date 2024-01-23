const std = @import("std");
const glfw = @import("mach-glfw");
const gl = @import("gl");
const ecs = @import("mach-ecs");

const World = @import("core/Engine.zig").World;

// TMP
const Math = @import("AntleneMath");
const Mesh = @import("graphics/Context.zig").GraphicContext;
const Camera = @import("graphics/Camera.zig").FlyingCamera;

pub const Application = @This();

world: World,

pub fn init(allocator: std.mem.Allocator) !*Application {
    var app = try allocator.create(Application);
    app.* = Application{
        .world = try World.init(allocator),
    };
    try app.world.send(.engine, .init, .{app});

    const floor = try app.world.entities.new();
    try app.world.entities.setComponent(floor, .graphic_context, .mesh, try Mesh.Plane(allocator));
    try app.world.entities.setComponent(floor, .mesh_pipeline, .transform, Math.Mat4x4.mul(
        Math.Mat4x4.rotateX(Math.degreesToRadians(f32, 90)),
        Math.Mat4x4.scale(.{ 10, 10, 10 }),
    ));
    try app.world.entities.setComponent(floor, .mesh_pipeline, .material, .{
        .diffuse = try Mesh.Texture.init(allocator, "./assets/Materials/Stylized_Stone_Floor/DiffuseColor.png"),
        .specular = try Mesh.Texture.init(allocator, "./assets/Materials/Stylized_Stone_Floor/Roughness.png"),
        .normal = try Mesh.Texture.init(allocator, "./assets/Materials/Stylized_Stone_Floor/NormalMap.png"),
        .shininess = 32.0,
        .tilingFactor = 20,
    });

    //const p = try app.world.entities.new();
    //try app.world.entities.setComponent(p, .graphic_context, .mesh, try Mesh.Sphere(allocator, 1.0, 24, 24));
    //try app.world.entities.setComponent(p, .mesh_pipeline, .transform, Math.Mat4x4.identity());
    //try app.world.entities.setComponent(p, .mesh_pipeline, .material, .{
    //    .diffuse = try Mesh.Texture.init(allocator, "./assets/Materials/Stylized_Stone_Floor/DiffuseColor.png"),
    //    .specular = try Mesh.Texture.init(allocator, "./assets/Materials/Stylized_Stone_Floor/Roughness.png"),
    //    .normal = try Mesh.Texture.init(allocator, "./assets/Materials/Stylized_Stone_Floor/NormalMap.png"),
    //    .shininess = 64.0,
    //});

    const CameraStep = struct {
        pub fn CameraStep(world: *World, entity: ecs.EntityID, _: f32) !void {
            const window: glfw.Window = world.mod.engine.state.window;
            const lastMousePosition = world.mod.engine.state.lastMousePosition;
            const currentMousePosition = world.mod.engine.state.currentMousePosition;
            const deltaMousePosition = currentMousePosition - lastMousePosition;
            var camera: Camera = world.entities.getComponent(entity, .graphic_context, .camera) orelse unreachable;
            if (window.getKey(.w) == .press or window.getKey(.w) == .repeat) {
                camera.translate(.Forward, 0.1);
            }
            if (window.getKey(.s) == .press or window.getKey(.s) == .repeat) {
                camera.translate(.Backward, 0.1);
            }
            if (window.getKey(.a) == .press or window.getKey(.a) == .repeat) {
                camera.translate(.Left, 0.1);
            }
            if (window.getKey(.d) == .press or window.getKey(.d) == .repeat) {
                camera.translate(.Right, 0.1);
            }
            camera.lookAngles(deltaMousePosition[0], -deltaMousePosition[1]);
            try world.entities.setComponent(entity, .graphic_context, .camera, camera);
        }
    }.CameraStep;

    const c = try app.world.entities.new();
    try app.world.entities.setComponent(c, .graphic_context, .camera, Camera.init(
        .{ 0, 3, 3 },
        .{ 0, 1, 0 },
        .{ 0, 0, -1 },
        -90.0,
        0.0,
        45.0,
        0.1,
        100.0,
        1280.0 / 720.0,
    ));
    try app.world.entities.setComponent(c, .graphic_context, .active, true);
    try app.world.entities.setComponent(c, .engine, .stepFunction, &CameraStep);

    return app;
}

pub fn deinit(self: *Application) !void {
    try self.world.send(.engine, .deinit, .{});
}

pub fn update(self: *Application) !bool {
    try self.world.send(.engine, .step, .{});
    return self.world.mod.engine.state.isRunning;
}

pub fn draw(self: *Application) !void {
    try self.world.send(.engine, .draw, .{});
    try self.world.send(.engine, .present, .{});
}
