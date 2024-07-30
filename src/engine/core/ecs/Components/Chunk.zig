const std = @import("std");
const Math = @import("AntleneMath");
const Graphics = @import("AntleneOpenGL");

pub const Chunk = @This();

// Each chunk is a cube of 32x32x32
pub const ChunkSize = 32;

pub const Tile = packed struct(u32) {
    x: u6, // 0 - 32
    y: u6, // 0 - 32
    z: u6, // 0 - 32
    id: u14, // 0 - 16383
};

pub const TileID = u16;

id: @Vector(2, i32),
worldPosition: @Vector(2, f32),
tiles: std.ArrayListUnmanaged(Tile) = .{},

gpuBuffer: ?Graphics.Buffer = null,

pub const MaxChunkGPUBufferSize = (@sizeOf(Tile) * ChunkSize * ChunkSize * ChunkSize) + @sizeOf(f32) * 2;
pub const MaxChunkIndicesBufferSize = ChunkSize * ChunkSize * ChunkSize * 6 * @sizeOf(u16);
// layout(std430, binding = ?) readonly buffer Chunk {
//      vec2 worldOffset;
//      uint tiles[]; // xyz (18 bits) + tileId (14 bits)
// }

pub fn init(id: @Vector(2, i32)) std.mem.Allocator.Error!Chunk {
    return .{
        .id = id,
        .worldPosition = getWorldPosition(id),
    };
}

pub fn deinit(self: *Chunk, allocator: std.mem.Allocator) void {
    if (self.gpuBuffer) |buffer| {
        buffer.deinit();
    }
    self.tiles.deinit(allocator);
}

pub fn getWorldPosition(id: @Vector(2, i32)) @Vector(2, f32) {
    const WorldMatrix = Math.Mat2x2.init(.{
        .{ 512, -512 },
        .{ 256, 256 },
    });

    return Math.Mat2x2.mulVec(
        WorldMatrix,
        @Vector(2, f32){
            @floatFromInt(id[0]),
            @floatFromInt(id[1]),
        },
    );
}
