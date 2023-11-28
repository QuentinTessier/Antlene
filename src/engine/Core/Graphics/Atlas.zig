const std = @import("std");
const Texture = @import("Texture.zig").Texture;

pub const Atlas = @This();

texture: Texture,
regions: std.ArrayListUnmanaged(@Vector(4, f32)) = .{},

pub fn deinit(self: *Atlas, allocator: std.mem.Allocator) void {
    self.regions.deinit(allocator);
}

pub fn addRegion(self: *Atlas, allocator: std.mem.Allocator, region: @Vector(4, f32)) !void {
    try self.regions.append(allocator, region);
}

const SerializedAtlas = struct {
    texture: [:0]const u8,
    regions: []const @Vector(4, f32),
};

pub fn saveToFile(self: *const Atlas, path: []const u8) !void {
    var file = try std.fs.cwd().createFile(path, .{});
    defer file.close();

    const serialized = .{
        .texture = self.texture.path,
        .regions = self.regions.items,
    };
    try std.json.stringify(serialized, .{}, file.writer());
}

pub fn loadFromFile(allocator: std.mem.Allocator, path: []const u8) !Atlas {
    var file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    var reader = std.json.Reader(1024, std.fs.File.Reader).init(allocator, file.reader());
    defer reader.deinit();
    var result = try std.json.parseFromTokenSource(SerializedAtlas, allocator, &reader, .{});
    defer result.deinit();

    var regions = std.ArrayListUnmanaged(@Vector(4, f32)){};
    try regions.insertSlice(allocator, 0, result.value.regions);
    return .{
        .texture = try Texture.load(result.value.texture, allocator),
        .regions = regions,
    };
}
