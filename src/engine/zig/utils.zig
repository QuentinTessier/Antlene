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
