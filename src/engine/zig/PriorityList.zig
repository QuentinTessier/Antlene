const std = @import("std");

pub fn CompareOptions(comptime T: type) type {
    return struct {
        field: std.meta.FieldEnum(T),
        lessThan: fn (T, T) bool,
    };
}

pub fn PriorityList(comptime T: type, comptime Compare: CompareOptions(T)) type {
    return struct {
        pub fn findIndex(array: []const T, new: T) usize {
            for (array, 0..) |elem, i| {
                if (Compare.lessThan(elem, new)) {
                    return i;
                }
            }
            return array.len;
        }
    };
}
