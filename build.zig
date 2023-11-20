const std = @import("std");

const zmath = @import("extern/zig-gamedev/libs/zmath/build.zig");
const zstbi = @import("extern/zig-gamedev/libs/zstbi/build.zig");
const znoise = @import("extern/zig-gamedev/libs/znoise/build.zig");
const zopengl = @import("./extern/zig-gamedev/libs/zopengl/build.zig");

inline fn thisDir() []const u8 {
    return comptime std.fs.path.dirname(@src().file) orelse ".";
}

pub fn buildGame(b: *std.Build, name: []const u8, root_file: []const u8, target: std.zig.CrossTarget, optimize: std.builtin.Mode) *std.Build.CompileStep {
    const zmath_pkg = zmath.package(b, target, optimize, .{});
    const zstbi_pkg = zstbi.package(b, target, optimize, .{});
    const znoise_pkg = znoise.package(b, target, optimize, .{});
    const zopengl_pkg = zopengl.package(b, target, optimize, .{});

    const window_system = b.dependency("AntleneWindowSystem", .{});

    const engine = b.createModule(.{ .source_file = .{
        .path = thisDir() ++ "/src/engine/antlene.zig",
    }, .dependencies = &.{
        .{ .name = "zmath", .module = zmath_pkg.zmath },
        .{ .name = "zstbi", .module = zstbi_pkg.zstbi },
        .{ .name = "znoise", .module = znoise_pkg.znoise },
        .{ .name = "zopengl", .module = zopengl_pkg.zopengl },
        .{ .name = "AntleneWindowSystem", .module = window_system.module("AntleneWindowSystem") },
    } });

    const game = b.createModule(.{ .source_file = .{
        .path = root_file,
    }, .dependencies = &.{
        .{ .name = "antlene", .module = engine },
        .{ .name = "zmath", .module = zmath_pkg.zmath },
        .{ .name = "znoise", .module = znoise_pkg.znoise },
    } });
    const exe = b.addExecutable(.{
        .name = name,
        .root_source_file = .{ .path = thisDir() ++ "/src/run.zig" },
        .target = target,
        .optimize = optimize,
    });
    exe.addModule("game", game);
    exe.addModule("antlene", engine);
    zstbi_pkg.link(exe);
    exe.linkSystemLibrary("opengl32");
    return exe;
}

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const exe = buildGame(b, "Antlene", "src/testbed/game.zig", target, optimize);
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
