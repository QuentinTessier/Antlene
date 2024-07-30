const std = @import("std");
const ecs = @import("ecs");
const Graphics = @import("AntleneOpenGL");

const Memory = @import("../../Memory.zig");

pub const ChunkRegistry = @This();

pub const Tile = packed struct(u32) {
    x: u6, // 0 - 32
    y: u6, // 0 - 32
    z: u6, // 0 - 32
    id: u14, // 0 - 16383
};

pub const Chunk = struct {
    tiles: []Tile = &.{},

    pub const ChunkSideSize = 32;
    pub const ChunkSize = ChunkSideSize * ChunkSideSize * ChunkSideSize;
    pub const ChunkGPUSize = ChunkSize * @sizeOf(Tile) + @sizeOf(f32) * 2;
};

chunks: std.AutoHashMap(@Vector(2, i32), Chunk),
currentCenterChunk: @Vector(2, i32) = .{ 0, 0 },

// GPU
// commands stores a list of 9 commands with the number of instances for each chunk
// buffer can store 9 full chunk
commands: Graphics.Buffer,
buffer: Graphics.Buffer,

pub fn init() Chunk {
    return .{
        .chunks = std.AutoHashMap(@Vector(2, i32), Chunk).init(Memory.Allocator),
        .commands = Graphics.Resources.CreateBuffer("ChunkCommands", .{
            .size = @sizeOf(Graphics.Resources.DrawElementsIndirectCommand) * 9,
        }, .{ .dynamic = true }),
        .buffer = Graphics.Resources.CreateBuffer("Chunks", .{
            .size = Chunk.ChunkGPUSize * 9,
        }, .{ .dynamic = true }),
    };
}

pub fn loadChunk(self: *ChunkRegistry, id: @Vector(2, i32)) !*Chunk {
    if (self.chunks.contains(id)) return;

    const x = try self.chunks.getOrPut(id);
    return x.value_ptr;
}

pub fn unloadChunk(self: *ChunkRegistry, id: @Vector(2, i32)) void {
    const c = self.chunks.get(id);
    if (c) |chunk| {
        Memory.Allocator.free(chunk.tiles);
    }
}
