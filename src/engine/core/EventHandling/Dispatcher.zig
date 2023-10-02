const std = @import("std");

pub fn DispatcherUnmanaged(comptime T: type) type {
    return struct {
        const Self = @This();

        const Listenner = struct { handle: *u8, callback: *const fn (*u8, *Self, T) anyerror!void };

        list: std.ArrayListUnmanaged(Listenner) = .{},

        pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
            self.list.deinit(allocator);
        }

        pub fn listen(self: *Self, allocator: std.mem.Allocator, handle: anytype, callback: anytype) !void {
            comptime {
                if (@typeInfo(@TypeOf(handle)) != .Pointer) {
                    @compileError("listen(handle, callback) :> handle must be a pointer");
                }
            }
            try self.list.append(allocator, .{ .handle = @ptrCast(handle), .callback = @ptrCast(callback) });
        }

        pub fn dispatch(self: *Self, data: T) !void {
            for (self.list.items) |*listener| {
                try listener.callback(listener.handle, self, data);
            }
        }
    };
}

pub fn Dispatcher(comptime T: type) type {
    return struct {
        const Self = @This();

        allocator: std.mem.Allocator,
        unmanaged: DispatcherUnmanaged(T) = .{},

        pub fn init(allocator: std.mem.Allocator) Self {
            return .{
                .allocator = allocator,
            };
        }

        pub fn deinit(self: *Self) void {
            self.unmanaged.deinit(self.allocator);
        }

        pub fn listen(self: *Self, handle: anytype, callback: anytype) !void {
            try self.unmanaged.listen(self.allocator, handle, callback);
        }

        pub fn dispatch(self: *Self, data: T) !void {
            try self.unmanaged.dispatch(data);
        }
    };
}
