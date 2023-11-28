const std = @import("std");
const rl = @import("raylib");

pub const Texture = @This();

path: [:0]const u8,
handle: rl.Texture2D,

pub fn load(path: [:0]const u8, allocator: std.mem.Allocator) !Texture {
    return .{
        .path = try allocator.dupeZ(u8, path),
        .handle = rl.LoadTexture(path),
    };
}

pub fn unload(self: *Texture, allocator: std.mem.Allocator) void {
    allocator.free(self.path);
    rl.UnloadTexture(self.handle);
}

pub fn debugDraw(self: *Texture, region: ?@Vector(4, f32), position: @Vector(2, f32)) void {
    if (region) |r| {
        const rec = rl.Rectangle{
            .x = r[0],
            .y = r[1],
            .width = r[2],
            .height = r[3],
        };
        rl.DrawTextureRec(self.handle, rec, .{ .x = position[0], .y = position[1] }, rl.WHITE);
    } else {
        const rec = rl.Rectangle{
            .x = 0,
            .y = 0,
            .width = @floatFromInt(self.handle.width),
            .height = @floatFromInt(self.handle.height),
        };
        rl.DrawTextureRec(self.handle, rec, .{ .x = position[0], .y = position[1] }, rl.WHITE);
    }
}
