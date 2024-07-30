const std = @import("std");

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

    // TODO: Cleanup import code
    const zjobs_dep = b.dependency("zjobs", .{
        .target = target,
        .optimize = optimize,
    });
    const zjobs = zjobs_dep.module("zjobs");

    const zpool_dep = b.dependency("zpool", .{
        .target = target,
        .optimize = optimize,
    });
    const zpool = zpool_dep.module("zpool");

    const znoise_dep = b.dependency("znoise", .{
        .target = target,
        .optimize = optimize,
    });
    const znoise = znoise_dep.module("znoise");

    const zigimg_dep = b.dependency("zigimg", .{});
    const zigimg = zigimg_dep.module("zigimg");

    const math_dep = b.dependency("AntleneMath", .{
        .target = target,
        .optimize = optimize,
    });
    const math = math_dep.module("AntleneMath");

    const window_dep = b.dependency("AntleneWindowSystem", .{});
    const window = window_dep.module("AntleneWindowSystem");

    const opengl_dep = b.dependency("AntleneOpenGL", .{});
    const opengl = opengl_dep.module("AntleneOpenGL");

    const ecs_dep = b.dependency("zig_ecs", .{ .target = target, .optimize = optimize });
    const ecs = ecs_dep.module("zig-ecs");

    const rc_dep = b.dependency("zigrc", .{});
    const rc = &rc_dep.artifact("zig-rc").root_module;

    const engine = b.createModule(.{
        .root_source_file = .{
            .path = "src/engine/Antlene.zig",
        },
    });
    engine.addImport("znoise", znoise);
    engine.addImport("zigimg", zigimg);
    engine.addImport("zpool", zpool);
    engine.addImport("zjobs", zjobs);
    engine.addImport("AntleneWindowSystem", window);
    engine.addImport("AntleneMath", math);
    engine.addImport("AntleneOpenGL", opengl);
    engine.addImport("ecs", ecs);
    engine.addImport("rc", rc);

    const game = b.addModule("game", .{
        .root_source_file = .{
            .path = root_file,
        },
    });
    game.addImport("antlene", engine);
    // TODO: This should only be imported in dev mode (zig language server can't make the link when these are only imported in the engine module).
    exe.root_module.addImport("rc", rc);
    exe.root_module.addImport("zigimg", zigimg);
    exe.root_module.addImport("zpool", zpool);
    exe.root_module.addImport("antlene", engine);
    exe.root_module.addImport("zjobs", zjobs);
    exe.root_module.addImport("AntleneMath", math);
    exe.root_module.addImport("AntleneWindowSystem", window);
    exe.root_module.addImport("AntleneOpenGL", opengl);
    exe.root_module.addImport("ecs", ecs);
    exe.root_module.addImport("game", game);
    exe.root_module.addImport("znoise", znoise);
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
