const std = @import("std");
const gl = @import("gl");
const img = @import("zigimg");

pub const Texture = @This();

handle: u32,
width: u32,
height: u32,

pub fn init(allocator: std.mem.Allocator, path: []const u8) !Texture {
    var image = try img.Image.fromFilePath(allocator, path);
    defer image.deinit();

    var self: Texture = .{
        .handle = 0,
        .width = @intCast(image.width),
        .height = @intCast(image.height),
    };

    gl.genTextures(1, @ptrCast(&self.handle));
    gl.bindTexture(gl.TEXTURE_2D, self.handle);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);

    switch (image.pixels) {
        .rgba32 => |pixels| {
            gl.texImage2D(
                gl.TEXTURE_2D,
                0,
                gl.RGBA,
                @intCast(image.width),
                @intCast(image.height),
                0,
                gl.RGBA,
                gl.UNSIGNED_BYTE,
                pixels.ptr,
            );
        },
        .rgb24 => |pixels| {
            gl.texImage2D(
                gl.TEXTURE_2D,
                0,
                gl.RGB,
                @intCast(image.width),
                @intCast(image.height),
                0,
                gl.RGB,
                gl.UNSIGNED_BYTE,
                pixels.ptr,
            );
        },
        .grayscale8 => |pixels| {
            gl.texImage2D(
                gl.TEXTURE_2D,
                0,
                gl.RED,
                @intCast(image.width),
                @intCast(image.height),
                0,
                gl.RED,
                gl.UNSIGNED_BYTE,
                pixels.ptr,
            );
        },
        else => {
            return error.UnsupportedFormat;
        },
    }
    gl.generateMipmap(gl.TEXTURE_2D);
    return self;
}

pub fn deinit(self: Texture) void {
    gl.deleteTextures(1, @ptrCast(&self.handle));
}
