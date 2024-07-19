const std = @import("std");
const ecs = @import("ecs");
const zpool = @import("zpool");
const zimg = @import("zigimg");
const Graphics = @import("AntleneOpenGL");

pub const TextureRegistry = @This();

const TextureStorageColumn = struct {
    texture: Graphics.Texture,
    path: ?[]const u8,
    canBeReleased: bool,
};

const TexturePool = zpool.Pool(16, 16, Graphics.Texture, TextureStorageColumn);
pub const TextureHandle = TexturePool.Handle;

texturePool: TexturePool,

pub fn init(allocator: std.mem.Allocator) TextureRegistry {
    return .{
        .texturePool = TexturePool.init(allocator),
    };
}

pub fn setup(_: *TextureRegistry) !void {}

pub fn deinit(self: *TextureRegistry) void {
    for (self.texturePool.columns.texture) |tex| {
        tex.deinit();
    }
    self.texturePool.deinit();
}

pub fn addTexture(self: *TextureRegistry, path: ?[]const u8, texture: Graphics.Texture) !TexturePool.Handle {
    return self.texturePool.add(.{
        .texture = texture,
        .path = path,
        .canBeReleased = false,
    });
}

pub fn removeTexture(self: *TextureRegistry, handle: TexturePool.Handle) !void {
    const texture: Graphics.Texture = try self.texturePool.getColumn(handle, .texture);
    texture.deinit();
    try self.texturePool.remove(handle);
}

pub fn loadTexture(self: *TextureRegistry, allocator: std.mem.Allocator, path: []const u8, mipmaps: ?u32) !TexturePool.Handle {
    var img = try zimg.Image.fromFilePath(allocator, path);
    defer img.deinit();

    const format: Graphics.Texture.Format = switch (img.pixelFormat()) {
        .rgba32 => .rgba8,
        .rgb24 => .rgb8_snorm,
        .grayscale8 => .r8,
        else => return error.UnsupportedType,
    };

    const info: struct {
        dataType: Graphics.Texture.DataType,
        internalFormat: Graphics.Texture.TextureInternalFormat,
    } = switch (img.pixelFormat()) {
        .rgba32 => .{ .dataType = .u8, .internalFormat = .rgba },
        .rgb24 => .{ .dataType = .u8, .internalFormat = .rgb },
        .grayscale8 => .{ .dataType = .u8, .internalFormat = .r },
        else => return error.UnsupportedType,
    };

    const texture = Graphics.Resources.CreateTexture(.{
        .name = path,
        .extent = .{ .width = @intCast(img.width), .height = @intCast(img.height), .depth = 0 },
        .format = format,
        .type = ._2D,
        .mipLevels = if (mipmaps) |m| m else 1,
    });
    texture.update(.{
        .extent = .{ .width = @intCast(img.width), .height = @intCast(img.height), .depth = 0 },
        .format = info.internalFormat,
        .type = info.dataType,
        .data = img.pixels.asConstBytes(),
    });

    return self.addTexture(path, texture);
}
