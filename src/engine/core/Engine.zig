const std = @import("std");
const glfw = @import("mach-glfw");
const gl = @import("gl");
const ecs = @import("mach-ecs");

const MeshPipeline = @import("../graphics/MeshPipeline.zig");
const GraphicContext = @import("../graphics/Context.zig").GraphicContext;
const Application = @import("../Application.zig");

const AntleneLogger = std.log.scoped(.Antlene);

pub fn glGetProcAddress(_: void, proc: [:0]const u8) ?gl.FunctionPointer {
    return glfw.getProcAddress(proc);
}

fn glfwOnWindowResize(window: glfw.Window, width: u32, height: u32) void {
    var app: *Application = window.getUserPointer(Application) orelse unreachable;
    app.world.send(.graphic_context, .resize, .{ width, height }) catch {};
}

pub const Engine = struct {
    isRunning: bool,
    window: glfw.Window,
    frameCounter: usize,
    lastFrameTime: f32,
    currentFrameTime: f32,
    lastMousePosition: @Vector(2, f32),
    currentMousePosition: @Vector(2, f32),

    pub const name = .engine;
    pub const logger = std.log.scoped(name);

    pub const components = struct {
        pub const stepFunction = *const fn (*World, ecs.EntityID, f32) anyerror!void;
    };

    pub const local = struct {
        pub fn init(world: *World, app: *Application) !void {
            const state = &world.mod.engine.state;
            state.window = glfw.Window.create(1280, 720, "Antlene", null, null, .{
                .opengl_profile = .opengl_core_profile,
                .context_version_major = 4,
                .context_version_minor = 6,
            }) orelse {
                logger.err("glfw: Failed to initialize window: {?s}", .{glfw.getErrorString()});
                return error.FailedToInitializeWindow;
            };
            glfw.makeContextCurrent(state.window);
            state.window.setInputModeCursor(.disabled);

            const window: glfw.Window = state.window;
            window.setUserPointer(app);
            window.setFramebufferSizeCallback(glfwOnWindowResize);

            state.isRunning = true;
            logger.info("Engine initialization finished, starting sub modules initialization.", .{});
            try world.send(null, .init, .{});
            try world.send(.graphic_context, .setClearColor, .{@Vector(4, f32){ 0, 0, 0, 1 }});

            state.frameCounter = 0;
            state.lastFrameTime = @floatCast(glfw.getTime());
            const cursor = window.getCursorPos();
            state.lastMousePosition = .{
                @floatCast(cursor.xpos),
                @floatCast(cursor.ypos),
            };
        }

        pub fn deinit(world: *World) !void {
            const window: glfw.Window = world.mod.engine.state.window;
            window.destroy();
            try world.send(null, .deinit, .{});
            world.deinit();
        }

        pub fn step(world: *World, engine: *World.Mod(Engine)) !void {
            glfw.pollEvents();
            if (engine.state.window.shouldClose() or engine.state.window.getKey(.escape) == .press) {
                engine.state.isRunning = false;
            }
            const cursor = engine.state.window.getCursorPos();
            engine.state.currentMousePosition = .{
                @floatCast(cursor.xpos),
                @floatCast(cursor.ypos),
            };
            engine.state.currentFrameTime = @floatCast(glfw.getTime());
            var q = world.entities.query(.{
                .all = &.{
                    .{ .engine = &.{.stepFunction} },
                },
            });
            while (q.next()) |archetype| {
                const fncs: []*const fn (*World, ecs.EntityID, f32) anyerror!void = archetype.slice(.engine, .stepFunction);
                const ids: []ecs.EntityID = archetype.slice(.entity, .id);
                for (fncs, 0..) |fnc, index| {
                    try fnc(world, ids[index], engine.state.currentFrameTime - engine.state.lastFrameTime);
                }
            }
            try world.send(null, .step, .{});
            engine.state.lastFrameTime = engine.state.currentFrameTime;
            engine.state.lastMousePosition = engine.state.currentMousePosition;
        }

        pub fn draw(world: *World) !void {
            try world.send(null, .prepareFrame, .{});
            try world.send(.mesh_pipeline, .drawMeshes, .{});
        }

        pub fn present(engine: *World.Mod(Engine)) !void {
            engine.state.window.swapBuffers();
        }
    };
};

pub const World = ecs.World(.{ Engine, GraphicContext, MeshPipeline });
