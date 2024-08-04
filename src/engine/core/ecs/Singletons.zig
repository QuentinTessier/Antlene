const std = @import("std");
const ecs = @import("ecs");
const utils = @import("../../zig/utils.zig");

pub const InputSingleton = @import("./Singletons/InputSingleton.zig");
pub const TextureRegistry = @import("./Singletons/TextureRegistry.zig");
pub const TimeSingleton = @import("./Singletons/TimeSingleton.zig");

const DefaultSingletons = .{
    InputSingleton,
    TextureRegistry,
    TimeSingleton,
};

pub fn registerSingleton(registry: *ecs.Registry, comptime T: type, allocator: std.mem.Allocator) !*T {
    var singletons = registry.singletons();
    const s: T = T.init(allocator);
    singletons.add(s);

    var actualS = singletons.get(T);
    try actualS.setup();

    return actualS;
}

pub fn registerDefaultSingletons(registry: *ecs.Registry, allocator: std.mem.Allocator) !void {
    var singletons = registry.singletons();
    inline for (DefaultSingletons) |T| {
        const s: T = blk: {
            if (comptime utils.FunctionCanReturnError(@typeInfo(@TypeOf(T.init)).Fn)) {
                break :blk try T.init(allocator);
            } else {
                break :blk T.init(allocator);
            }
        };
        singletons.add(s);

        var actualS = singletons.get(T);
        try actualS.setup();
    }
}

pub fn deinitDefaultSingletons(registry: *ecs.Registry, _: std.mem.Allocator) void {
    var singletons = registry.singletons();
    inline for (DefaultSingletons) |T| {
        var s = singletons.get(T);
        s.deinit();
    }
}
