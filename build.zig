const std = @import("std");
const raylib = @import("extern/raylib.zig/build.zig");
const zflecs = @import("extern/zig-gamedev/libs/zflecs/build.zig");

pub fn buildAntleneGame(
    b: *std.Build,
    name: []const u8,
    root_file: []const u8,
    target: std.zig.CrossTarget,
    optimize: std.builtin.Mode,
) *std.Build.CompileStep {
    const exe = b.addExecutable(.{
        .name = name,
        .root_source_file = .{
            .path = "src/main.zig",
        },
        .target = target,
        .optimize = optimize,
    });
    raylib.addTo(b, exe, target, optimize);

    const zflecs_pkg = zflecs.package(b, target, optimize, .{});
    zflecs_pkg.link(exe);

    const engine = b.createModule(.{
        .source_file = .{
            .path = "src/engine/Antlene.zig",
        },
        .dependencies = &.{
            .{ .name = "raylib", .module = exe.modules.get("raylib") orelse unreachable },
            .{ .name = "zflecs", .module = zflecs_pkg.zflecs },
        },
    });
    const game = b.createModule(.{
        .source_file = .{
            .path = root_file,
        },
        .dependencies = &.{
            .{ .name = "antlene", .module = engine },
            //.{ .name = "zflecs", .module = zflecs_pkg.zflecs },
        },
    });
    exe.addModule("antlene", engine);
    exe.addModule("game", game);
    return exe;
}

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const exe = buildAntleneGame(b, "Testbed", "src/testbed/main.zig", target, optimize);
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const run_unit_tests = b.addRunArtifact(unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}
