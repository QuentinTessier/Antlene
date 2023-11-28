const std = @import("std");
const rl = @import("raylib");
const SceneManager = @import("SceneManager.zig");

pub const Application = struct {
    pub const Parameters = struct {
        name: [:0]const u8,
        version: u32,
        init: *const fn (*Application) anyerror!void,

        windowInfo: struct {
            name: [:0]const u8,
            width: i32,
            height: i32,
        },
    };

    name: [:0]const u8,
    version: u32,

    allocator: std.mem.Allocator,

    sceneManager: SceneManager,

    pub fn init(allocator: std.mem.Allocator, params: Parameters) anyerror!Application {
        rl.SetConfigFlags(rl.ConfigFlags{ .FLAG_WINDOW_RESIZABLE = true });
        rl.InitWindow(params.windowInfo.width, params.windowInfo.height, params.windowInfo.name);
        rl.SetTargetFPS(60);
        return .{
            .name = params.name,
            .version = params.version,

            .allocator = allocator,
            .sceneManager = .{},
        };
    }

    pub fn deinit(self: *Application) void {
        self.sceneManager.deinit(self.allocator);
        rl.CloseWindow();
    }

    pub fn run(self: *Application) anyerror!void {
        _ = self;
        while (!rl.WindowShouldClose()) {
            rl.BeginDrawing();

            rl.ClearBackground(rl.BLACK);

            rl.EndDrawing();
        }
    }
};
