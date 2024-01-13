const std = @import("std");

pub fn buildAntleneGame(b: *std.Build, name: []const u8, root_file: []const u8, target: std.Build.ResolvedTarget, optimize: std.builtin.Mode) *std.Build.Step.Compile {
    const exe = b.addExecutable(.{
        .name = name,
        .root_source_file = .{
            .path = "src/main.zig",
        },
        .target = target,
        .optimize = optimize,
    });

    const opengl = b.createModule(.{
        .root_source_file = .{
            .path = "extern/gl/gl4_6.zig",
        },
    });

    // Use mach-glfw
    const glfw_dep = b.dependency("mach_glfw", .{
        .target = target,
        .optimize = optimize,
    });
    const glfw = glfw_dep.module("mach-glfw");
    exe.root_module.addImport("mach-glfw", glfw);
    @import("mach_glfw").addPaths(exe);

    const engine = b.createModule(.{
        .root_source_file = .{
            .path = "src/engine/Antlene.zig",
        },
    });
    engine.addImport("gl", opengl);
    engine.addImport("mach-glfw", glfw);
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
