const std = @import("std");
const gl = @import("../Platform/gl/gl.zig");
const zstbi = @import("zstbi");

pub const Texture = @This();

pub const Format = enum(u32) {
    Ru8,
    RGBu8,
    RBGAu8,

    Rf32,
    RGBf32,
    RBGAf32,
};

handle: u32,
extent: @Vector(2, u32),
format: Format,

pub fn createEmpty(width: i32, height: i32, format: Texture.Format, hasMipmap: bool) Texture {
    var handle: u32 = 0;
    gl.genTextures(1, &handle);
    gl.bindTexture(gl.TEXTURE_2D, handle);

    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
    switch (format) {
        .Ru8 => {
            gl.texImage2D(gl.TEXTURE_2D, 0, gl.R8, width, height, 0, gl.RED, gl.UNSIGNED_BYTE, null);
        },
        .RGBu8 => {
            gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGB8, width, height, 0, gl.RGB, gl.UNSIGNED_BYTE, null);
        },
        .RBGAu8 => {
            gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA8, width, height, 0, gl.RGBA, gl.UNSIGNED_BYTE, null);
        },
        .Rf32 => {
            gl.texImage2D(gl.TEXTURE_2D, 0, gl.R32F, width, height, 0, gl.RED, gl.FLOAT, null);
        },
        .RGBf32 => {
            gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGB32F, width, height, 0, gl.RGB, gl.FLOAT, null);
        },
        .RBGAf32 => {
            gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA32F, width, height, 0, gl.RGBA, gl.FLOAT, null);
        },
    }
    if (hasMipmap) {
        gl.generateMipmap(gl.TEXTURE_2D);
    }
    return Texture{
        .handle = handle,
        .extent = .{ @intCast(width), @intCast(height) },
        .format = format,
    };
}

pub fn createFromMemory(width: i32, height: i32, data: [*]u8, format: Texture.Format, hasMipmap: bool) Texture {
    var handle: u32 = 0;
    gl.genTextures(1, &handle);
    gl.bindTexture(gl.TEXTURE_2D, handle);

    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
    switch (format) {
        .Ru8 => {
            gl.texImage2D(gl.TEXTURE_2D, 0, gl.R8, width, height, 0, gl.RED, gl.UNSIGNED_BYTE, data);
        },
        .RGBu8 => {
            gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGB8, width, height, 0, gl.RGB, gl.UNSIGNED_BYTE, data);
        },
        .RBGAu8 => {
            gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA8, width, height, 0, gl.RGBA, gl.UNSIGNED_BYTE, data);
        },
        .Rf32 => {
            gl.texImage2D(gl.TEXTURE_2D, 0, gl.R32F, width, height, 0, gl.RED, gl.FLOAT, data);
        },
        .RGBf32 => {
            gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGB32F, width, height, 0, gl.RGB, gl.FLOAT, data);
        },
        .RBGAf32 => {
            gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA32F, width, height, 0, gl.RGBA, gl.FLOAT, data);
        },
    }
    if (hasMipmap) {
        gl.generateMipmap(gl.TEXTURE_2D);
    }
    return Texture{
        .handle = handle,
        .extent = .{ @intCast(width), @intCast(height) },
        .format = format,
    };
}

pub fn createFromImage(image: *const zstbi.Image, hasMipmap: bool) Texture {
    var handle: u32 = 0;
    gl.genTextures(1, &handle);
    gl.bindTexture(gl.TEXTURE_2D, handle);

    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR);
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);

    switch (image.num_components) {
        1 => {
            gl.texImage2D(gl.TEXTURE_2D, 0, gl.R8, @intCast(image.width), @intCast(image.height), 0, gl.RED, gl.UNSIGNED_BYTE, image.data.ptr);
        },
        3 => {
            gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGB8, @intCast(image.width), @intCast(image.height), 0, gl.RGB, gl.UNSIGNED_BYTE, image.data.ptr);
        },
        4 => {
            gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA8, @intCast(image.width), @intCast(image.height), 0, gl.RGBA, gl.UNSIGNED_BYTE, image.data.ptr);
        },
        else => unreachable,
    }
    if (hasMipmap) {
        gl.generateMipmap(gl.TEXTURE_2D);
    }
    return Texture{
        .handle = handle,
        .extent = .{ image.width, image.height },
        .format = switch (image.num_components) {
            1 => .Ru8,
            3 => .RGBu8,
            4 => .RBGAu8,
            else => unreachable,
        },
    };
}

// TODO: Check if path exist before opening with zstbi (zstbi crashes without reporting an error and the stack trace don't mention 'zstbi.Image.loadFromFile' has the cause sometimes).
pub fn createFromPath(path: [:0]const u8, hasMipmap: bool) anyerror!Texture {
    const info = zstbi.Image.info(path);
    var img = try zstbi.Image.loadFromFile(path, info.num_components);
    defer img.deinit();

    return Texture.createFromImage(&img, hasMipmap);
}

pub fn destroy(self: *Texture) void {
    gl.deleteTextures(1, &self.handle);
    self.handle = 0;
    self.extent = .{ 0, 0 };
}
