const std = @import("std");
const gl = @import("gl");

pub const Stage = enum(gl.GLenum) {
    vertex = gl.VERTEX_SHADER,
    fragment = gl.FRAGMENT_SHADER,
};

// TODO: Use ShaderDescription to enable Shader Specialization
pub fn SPIRVShader(comptime stage: Stage, comptime ShaderDescription: anytype) type {
    _ = ShaderDescription; // autofix
    return struct {
        handle: u32,

        pub fn initFromFile(allocator: std.mem.Allocator, path: []const u8) !@This() {
            if (!std.mem.endsWith(u8, path, ".spv")) {
                return error.InvalidFileExtension;
            }

            var file = try std.fs.cwd().openFile(path, .{});
            defer file.close();

            const content = try file.readToEndAlloc(allocator, 100_000);
            defer allocator.free(content);

            const shader = gl.createShader(@intFromEnum(stage));
            errdefer gl.deleteShader(shader);
            gl.shaderBinary(1, @ptrCast(&shader), gl.SHADER_BINARY_FORMAT_SPIR_V, content.ptr, @intCast(content.len));
            gl.specializeShader(shader, "main", 0, null, null);

            var isCompiled: i32 = 0;
            gl.getShaderiv(shader, gl.COMPILE_STATUS, &isCompiled);
            if (isCompiled != gl.TRUE) {
                return error.ShaderCompilationFailed;
            }
            return .{
                .handle = shader,
            };
        }

        pub fn deinit(self: @This()) void {
            gl.deleteShader(self.handle);
        }

        pub fn attach(self: @This(), program: Program) void {
            gl.attachShader(program.handle, self.handle);
        }
    };
}

pub const Shader = struct {
    handle: u32,

    fn getShaderType(path: []const u8) gl.GLenum {
        if (std.mem.endsWith(u8, path, ".vs")) {
            return gl.VERTEX_SHADER;
        } else if (std.mem.endsWith(u8, path, ".fs")) {
            return gl.FRAGMENT_SHADER;
        } else if (std.mem.endsWith(u8, path, ".gs")) {
            return gl.GEOMETRY_SHADER;
        } else if (std.mem.endsWith(u8, path, ".tcs")) {
            return gl.TESS_CONTROL_SHADER;
        } else if (std.mem.endsWith(u8, path, ".tes")) {
            return gl.TESS_EVALUATION_SHADER;
        }
        return 0;
    }

    pub fn initFromFile(allocator: std.mem.Allocator, path: []const u8) !@This() {
        var file = try std.fs.cwd().openFile(path, .{});
        defer file.close();

        const source = try file.readToEndAllocOptions(allocator, 100_000, null, 1, 0);
        defer allocator.free(source);

        const stage = getShaderType(path);
        if (stage == 0) {
            return error.InvalidFileExtension;
        }

        const shader = gl.createShader(stage);
        errdefer gl.deleteShader(shader);
        gl.shaderSource(shader, 1, @ptrCast(&source.ptr), null);
        gl.compileShader(shader);

        var success: i32 = 0;
        gl.getShaderiv(shader, gl.COMPILE_STATUS, @ptrCast(&success));
        if (success != gl.TRUE) {
            var buffer: [1024]u8 = undefined;
            gl.getShaderInfoLog(shader, 1024, null, (&buffer).ptr);
            std.log.err("{s}", .{buffer});
            return error.FailedToCompileShader;
        }
        return .{ .handle = shader };
    }

    pub fn initFromSource(source: []const u8, stage: Stage) !@This() {
        const shader = gl.createShader(@intFromEnum(stage));
        errdefer gl.deleteShader(shader);
        gl.shaderSource(shader, 1, @ptrCast(&source.ptr), null);
        gl.compileShader(shader);

        var success: i32 = 0;
        gl.getShaderiv(shader, gl.COMPILE_STATUS, @ptrCast(&success));
        if (success != gl.TRUE) {
            var buffer: [1024]u8 = undefined;
            gl.getShaderInfoLog(shader, 1024, null, (&buffer).ptr);
            std.log.err("{s}", .{buffer});
            return error.FailedToCompileShader;
        }
        return .{ .handle = shader };
    }

    pub fn deinit(self: @This()) void {
        gl.deleteShader(self.handle);
    }

    pub fn attach(self: @This(), program: Program) void {
        gl.attachShader(program.handle, self.handle);
    }
};

pub const Program = struct {
    handle: u32,

    pub fn begin() Program {
        return .{
            .handle = gl.createProgram(),
        };
    }

    pub fn end(self: Program) !void {
        gl.linkProgram(self.handle);

        var isLinked: i32 = 0;
        gl.getProgramiv(self.handle, gl.LINK_STATUS, &isLinked);
        if (isLinked != gl.TRUE) {
            var size: isize = 0;
            var buffer: [1024]u8 = undefined;
            gl.getProgramInfoLog(self.handle, 1024, @ptrCast(&size), (&buffer).ptr);
            std.log.err("Failed to link program: {s}", .{buffer[0..@intCast(size)]});
            return error.ProgramLinkingFailed;
        }
    }

    pub fn deinit(self: Program) void {
        gl.deleteProgram(self.handle);
    }

    pub fn use(self: Program) void {
        gl.useProgram(self.handle);
    }
};
