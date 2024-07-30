const std = @import("std");

pub const DefaultMemoryRequirement = 10_000;

var GPA: std.heap.GeneralPurposeAllocator(.{}) = undefined;
var mem: []u8 = undefined;

var AntleneMemoryAllocator: std.heap.GeneralPurposeAllocator(.{}) = undefined;
pub var Allocator: std.mem.Allocator = undefined;

pub fn init() void {
    AntleneMemoryAllocator = std.heap.GeneralPurposeAllocator(.{}){};
    Allocator = AntleneMemoryAllocator.allocator();
}

pub fn deinit() void {
    const state = AntleneMemoryAllocator.deinit();
    switch (state) {
        .ok => std.log.info("Antlene(Memory): GeneralPurposeAllocator no memory leak", .{}),
        .leak => std.log.warn("Antlene(Memory): GeneralPurposeAllocator leaked memory", .{}),
    }
}

pub fn createArenaAllocator() std.heap.ArenaAllocator {
    return std.heap.ArenaAllocator.init(Allocator);
}
