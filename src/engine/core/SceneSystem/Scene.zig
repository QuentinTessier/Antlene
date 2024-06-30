const std = @import("std");

pub const Scene = @This();

onCreate: *const fn (*Scene, allocator: std.mem.Allocator) anyerror!void,
onDestroy: *const fn (*Scene, allocator: std.mem.Allocator) anyerror!void,
