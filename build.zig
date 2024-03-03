const std = @import("std");

const zflecs = @import("./extern/zig-gamedev/libs/zflecs/build.zig");

pub fn buildAntleneGame(
    b: *std.Build,
    name: []const u8,
    root_file: []const u8,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.Mode,
) *std.Build.Step.Compile {
    const exe = b.addExecutable(.{
        .name = name,
        .root_source_file = .{
            .path = "src/main.zig",
        },
        .target = target,
        .optimize = optimize,
    });

    const flecs = zflecs.package(b, target, optimize, .{});

    const zigimg_dep = b.dependency("zigimg", .{});
    const zigimg = zigimg_dep.module("zigimg");
    // Use mach-glfw
    const glfw_dep = b.dependency("mach_glfw", .{
        .target = target,
        .optimize = optimize,
    });
    const glfw = glfw_dep.module("mach-glfw");
    exe.root_module.addImport("mach-glfw", glfw);
    @import("mach_glfw").addPaths(exe);

    const math_dep = b.dependency("AntleneMath", .{
        .target = target,
        .optimize = optimize,
    });
    const math = math_dep.module("AntleneMath");

    const opengl_dep = b.dependency("AntleneOpenGL", .{});
    const opengl = opengl_dep.module("AntleneOpenGL");

    const engine = b.createModule(.{
        .root_source_file = .{
            .path = "src/engine/Antlene.zig",
        },
    });
    engine.addImport("mach-glfw", glfw);
    engine.addImport("zigimg", zigimg);
    engine.addImport("AntleneMath", math);
    engine.addImport("AntleneOpenGL", opengl);
    engine.addImport("zflecs", flecs.zflecs);
    flecs.link(exe);

    const game = b.createModule(.{
        .root_source_file = .{
            .path = root_file,
        },
    });
    game.addImport("Antlene", engine);
    exe.root_module.addImport("antlene", engine);
    exe.root_module.addImport("game", game);
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
