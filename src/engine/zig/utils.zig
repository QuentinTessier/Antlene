const std = @import("std");

pub fn GetDemangledTypeName(comptime T: type) [:0]const u8 {
    const name = @typeName(T);
    const index = std.mem.indexOf(u8, name, ".");
    if (index) |i| {
        return name[i..];
    } else {
        return name;
    }
}

pub fn FunctionCanReturnError(comptime Info: std.builtin.Type.Fn) bool {
    if (Info.return_type) |rtype| {
        return (@typeInfo(rtype) == .ErrorUnion);
    } else {
        return false;
    }
}

pub const Profiler = struct {
    start: std.time.Instant,

    pub fn start() !Profiler {
        return .{
            .start = try std.time.Instant.now(),
        };
    }

    pub fn end(self: *const Profiler) !void {
        const e = try std.time.Instant.now();
        const elapsed = e.since(self.start);

        const fElapsed = @as(f64, @floatFromInt(elapsed)) / @as(f32, std.time.ns_per_s);
        std.log.info("{d:.3}s", .{fElapsed});
    }
};
