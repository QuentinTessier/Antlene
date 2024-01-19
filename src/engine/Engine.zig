const std = @import("std");
const glfw = @import("mach-glfw");
const gl = @import("gl");
const ecs = @import("mach-ecs");

const AntleneLogger = std.log.scoped(.Antlene);

pub const Engine = struct {
    isRunning: bool,
    window: glfw.Window,

    pub const name = .engine;
    pub const logger = std.log.scoped(name);

    fn glGetProcAddress(_: void, proc: [:0]const u8) ?gl.FunctionPointer {
        return glfw.getProcAddress(proc);
    }

    pub const local = struct {
        pub fn init(world: *World) !void {
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

            state.isRunning = true;
            logger.info("Engine initialization finished, starting sub modules initialization.", .{});
            try world.send(null, .init, .{});
        }

        pub fn deinit(world: *World) !void {
            const window: glfw.Window = world.mod.engine.state.window;
            window.destroy();
            try world.send(null, .deinit, .{});
            world.deinit();
        }

        pub fn tick(world: *World, engine: *World.Mod(Engine)) !void {
            glfw.pollEvents();
            if (engine.state.window.shouldClose()) {
                engine.state.isRunning = false;
            }
            try world.send(null, .tick, .{});
        }

        pub fn present(engine: *World.Mod(Engine)) !void {
            engine.state.window.swapBuffers();
        }
    };
};

pub const World = ecs.World(.{Engine});
