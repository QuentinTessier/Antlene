const std = @import("std");

pub const AtlasBuilder = @This();

const Atlas = @import("../ECS/Components/Atlas.zig");
const Texture = @import("Texture.zig");

const SerializedAtlas = struct {
    texture: [:0]const u8,
    regions: []const @Vector(4, f32),
};

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
