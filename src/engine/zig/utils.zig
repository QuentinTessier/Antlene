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
