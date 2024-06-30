const std = @import("std");

pub fn DispatcherUnmanaged(comptime T: type) type {
    return struct {
        pub const CallbackType = *const fn (*@This(), *anyopaque, T) void;

        listener: std.ArrayListUnmanaged(struct {
            obj: *anyopaque,
            callback: CallbackType,
        }),

        pub fn init() @This() {
            return .{ .listener = .{} };
        }

        pub fn getHolder(self: *@This(), comptime HolderType: type, name: []const u8) *HolderType {
            return @fieldParentPtr(name, self);
        }

        pub fn listen(self: *@This(), allocator: std.mem.Allocator, obj: *anyopaque, callback: CallbackType) !void {
            self.listener.append(allocator, .{ .obj = obj, .callback = callback });
        }

        pub fn dispatch(self: *@This(), data: T) void {
            for (self.listener.items) |listener| {
                listener.callback(self, listener.obj, data);
            }
        }
    };
}

pub fn Dispatcher(comptime T: type) type {
    return struct {
        pub const CallbackType = *const fn (*@This(), *anyopaque, T) void;

        listener: std.ArrayList(struct {
            obj: *anyopaque,
            callback: CallbackType,
        }),

        pub fn init(allocator: std.mem.Allocator) @This() {
            var self: @This() = undefined;
            self.listener.init(allocator);
            return self;
        }

        pub fn getHolder(self: *@This(), comptime HolderType: type, name: []const u8) *HolderType {
            return @fieldParentPtr(name, self);
        }

        pub fn listen(self: *@This(), obj: *anyopaque, callback: CallbackType) !void {
            self.listener.append(.{ .obj = obj, .callback = callback });
        }

        pub fn dispatch(self: *@This(), data: T) void {
            for (self.listener.items) |listener| {
                listener.callback(self, listener.obj, data);
            }
        }
    };
}
