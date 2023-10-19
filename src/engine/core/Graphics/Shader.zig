const std = @import("std");
const gl = @import("../Platform/gl/gl.zig");

pub const Error = error{
    InvalidFileExtension,
    FailedShaderCompilation,
    FailedProgramLinking,
};

pub const Stage = enum(u32) {
    Vertex,
    Tessellation,
    Geometry,
    Fragment,
    Compute,

    pub fn toGL(stage: Stage) u32 {
        return switch (stage) {
            .Vertex => gl.VERTEX_SHADER,
            .Geometry => gl.GEOMETRY_SHADER,
            .Fragment => gl.FRAGMENT_SHADER,
            .Compute => gl.COMPUTE_SHADER,
            else => 0,
        };
    }
};

pub const CompiledShader = struct {
    stage: Stage,
    handle: u32,
};

pub const Program = u32;

fn extensionToStage(filepath: []const u8) Error!Stage {
    if (std.mem.endsWith(u8, filepath, ".vert")) {
        return Stage.Vertex;
    } else if (std.mem.endsWith(u8, filepath, ".tess")) {
        return Stage.Tessellation;
    } else if (std.mem.endsWith(u8, filepath, ".geom")) {
        return Stage.Geometry;
    } else if (std.mem.endsWith(u8, filepath, ".frag")) {
        return Stage.Fragment;
    } else {
        return error.InvalidFileExtension;
    }
}

fn loadShaderFile(allocator: std.mem.Allocator, filepath: []const u8) !CompiledShader {
    var file = try std.fs.cwd().openFile(filepath, .{});
    defer file.close();

    var endPos = try file.getEndPos();
    var source = try allocator.allocSentinel(u8, endPos, 0);
    _ = try file.readAll(source);

    var stage = try extensionToStage(filepath);

    var handle = gl.createShader(stage.toGL());
    gl.shaderSource(handle, 1, @ptrCast(&(source.ptr)), null);
    gl.compileShader(handle);

    var status: i32 = 0;
    gl.getShaderiv(handle, gl.COMPILE_STATUS, &status);
    if (status != gl.TRUE) {
        var buffer: [1024:0]u8 = undefined;
        gl.getShaderInfoLog(handle, 1024, null, &buffer);
        std.log.err("Failed to compile shader {s} with status {}:\n{s}", .{ filepath, status, buffer });
        return error.FailedShaderCompilation;
    }
    allocator.free(source);
    return .{
        .stage = stage,
        .handle = handle,
    };
}

fn linkProgram(stages: []const CompiledShader) !Program {
    var program = gl.createProgram();
    for (stages) |stage| {
        gl.attachShader(program, stage.handle);
    }
    gl.linkProgram(program);

    var status: i32 = 0;
    gl.getProgramiv(program, gl.LINK_STATUS, &status);
    if (status != gl.TRUE) {
        var buffer: [1024:0]u8 = undefined;
        gl.getProgramInfoLog(program, 1024, null, &buffer);
        std.log.err("Failed to link program with status {}:\n{s}", .{ status, buffer });
        return error.FailedProgramLinking;
    }
    return program;
}

pub fn loadProgram(allocator: std.mem.Allocator, stages: []const []const u8) !Program {
    if (stages.len == 0) {
        std.log.err("Failed to link program no file given", .{});
        return error.FailedProgramLinking;
    }

    var shaders: [16]CompiledShader = undefined;
    for (stages, 0..) |path, index| {
        shaders[index] = try loadShaderFile(allocator, path);
    }
    var program = try linkProgram(shaders[0..stages.len]);
    for (shaders[0..stages.len]) |s| {
        gl.deleteShader(s.handle);
    }
    return program;
}

pub fn getUniformLocation(prog: Program, name: [*:0]const u8) i32 {
    gl.useProgram(prog);
    defer gl.useProgram(0);

    return gl.getUniformLocation(prog, name);
}
