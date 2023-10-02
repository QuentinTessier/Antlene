const std = @import("std");

const zmath = @import("extern/zig-gamedev/libs/zmath/build.zig");

inline fn thisDir() []const u8 {
    return comptime std.fs.path.dirname(@src().file) orelse ".";
}

pub fn buildGame(b: *std.Build, name: []const u8, root_file: []const u8, target: std.zig.CrossTarget, optimize: std.builtin.Mode) *std.Build.CompileStep {
    const zmath_pkg = zmath.package(b, target, optimize, .{});
    const engine = b.createModule(.{ .source_file = .{
        .path = thisDir() ++ "/src/engine/antlene.zig",
    }, .dependencies = &.{
        .{ .name = "zmath", .module = zmath_pkg.zmath },
    } });

    const game = b.createModule(.{ .source_file = .{
        .path = root_file,
    }, .dependencies = &.{
        .{ .name = "antlene", .module = engine },
        .{ .name = "zmath", .module = zmath_pkg.zmath },
    } });
    const exe = b.addExecutable(.{
        .name = name,
        .root_source_file = .{ .path = thisDir() ++ "/src/run.zig" },
        .target = target,
        .optimize = optimize,
    });
    exe.addModule("game", game);
    exe.addModule("antlene", engine);
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
