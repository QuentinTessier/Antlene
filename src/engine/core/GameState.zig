const std = @import("std");

pub const GameStateHandle = *u32;

pub fn MakeGameState(comptime T: type) type {
    if (@typeInfo(T) != .Struct) @panic("MakeGameState(type) only supports struct");

    const default_field = std.builtin.Type.StructField{
        .name = "handle",
        .type = u32,
        .default_value = null,
        .is_comptime = false,
        .alignment = @alignOf(T),
    };
    const fields = std.meta.fields(T) ++ [1]std.builtin.Type.StructField{default_field};
    return @Type(.{
        .Struct = .{
            .layout = .Auto,
            .is_tuple = false,
            .fields = fields,
            .decls = &[_]std.builtin.Type.Declaration{},
        },
    });
}

pub fn newGameState(comptime T: type, allocator: std.mem.Allocator) !GameStateHandle {
    const GameStateType = MakeGameState(T);
    var ptr = try allocator.create(GameStateType);
    return &ptr.handle;
}

pub fn destroyGameState(comptime T: type, allocator: std.mem.Allocator, handle: GameStateHandle) void {
    const GameStateType = MakeGameState(T);
    const ptr = @fieldParentPtr(GameStateType, "handle", handle);
    allocator.destroy(ptr);
}
