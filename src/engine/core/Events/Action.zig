const std = @import("std");

pub fn KeyAction(comptime ResultType: type) type {
    return struct {
        keys: std.AutoHashMapUnmanaged(i32, ResultType) = .{},
        combine: *const fn (ResultType, ResultType) ResultType,
        result: ResultType,

        pub fn update(self: *@This()) void {}
    };
}
