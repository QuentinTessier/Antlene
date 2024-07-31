const std = @import("std");

fn addAntleneModules(
    b: *std.Build,
    antlene: *std.Build.Module,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.Mode,
) void {
    const zjobs_dep = b.dependency("zjobs", .{ .target = target, .optimize = optimize });
    const znoise_dep = b.dependency("znoise", .{ .target = target, .optimize = optimize });
    const zigimg_dep = b.dependency("zigimg", .{});
    const zpool_dep = b.dependency("zpool", .{ .target = target, .optimize = optimize });
    const window_dep = b.dependency("AntleneWindowSystem", .{});
    const math_dep = b.dependency("AntleneMath", .{ .target = target, .optimize = optimize });
    const opengl_dep = b.dependency("AntleneOpenGL", .{});
    const ecs_dep = b.dependency("entt", .{ .target = target, .optimize = optimize });
    const rc_dep = b.dependency("zigrc", .{});

    antlene.addImport("zjobs", zjobs_dep.module("root"));
    antlene.addImport("znoise", znoise_dep.module("root"));
    antlene.linkLibrary(znoise_dep.artifact("FastNoiseLite"));
    antlene.addImport("zigimg", zigimg_dep.module("zigimg"));
    antlene.addImport("zpool", zpool_dep.module("root"));
    antlene.addImport("zjobs", zjobs_dep.module("root"));
    antlene.addImport("AntleneWindowSystem", window_dep.module("AntleneWindowSystem"));
    antlene.addImport("AntleneMath", math_dep.module("AntleneMath"));
    antlene.addImport("AntleneOpenGL", opengl_dep.module("AntleneOpenGL"));
    antlene.addImport("ecs", ecs_dep.module("zig-ecs"));
    antlene.linkLibrary(rc_dep.artifact("zig-rc"));
}

pub fn buildAntleneGame(
    b: *std.Build,
    name: []const u8,
    game: *std.Build.Module,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.Mode,
) *std.Build.Step.Compile {
    const exe = b.addExecutable(.{
        .name = name,
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const engine = b.createModule(.{
        .root_source_file = b.path("./src/engine/Antlene.zig"),
    });
    addAntleneModules(b, engine, target, optimize);

    game.addImport("antlene", engine);

    exe.root_module.addImport("antlene", engine);
    exe.root_module.addImport("game", game);
    return exe;
}

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const testbed = b.addModule("TestbedGame", .{
        .root_source_file = b.path("src/testbed/main.zig"),
    });

    const exe = buildAntleneGame(b, "Testbed", testbed, target, optimize);
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const unit_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_unit_tests = b.addRunArtifact(unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}
