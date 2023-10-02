const std = @import("std");

pub const EventBus = struct {
    pub const EventCallback = *const fn (listener: *anyopaque, sender: ?*anyopaque, data: *const anyopaque) void;
    pub const ListenerArray = std.ArrayListUnmanaged(struct { listener: *anyopaque, callback: EventCallback });

    eventTypes: std.StringArrayHashMapUnmanaged(ListenerArray) = .{},

    pub fn deinit(self: *EventBus, allocator: std.mem.Allocator) void {
        var ite = self.eventTypes.iterator();
        while (ite.next()) |item| {
            item.value_ptr.deinit(allocator);
        }
        self.eventTypes.deinit(allocator);
    }

    pub fn register(self: *EventBus, allocator: std.mem.Allocator, comptime T: type) !void {
        const name = @typeName(T);
        if (self.eventTypes.get(name)) |_| {
            std.log.info("This event type {s} has already been registered", .{name});
        } else {
            try self.eventTypes.put(allocator, name, .{});
        }
    }

    pub fn listen(self: *EventBus, allocator: std.mem.Allocator, comptime T: type, listener: anytype, callback: anytype) !void {
        const name = @typeName(T);

        if (self.eventTypes.getPtr(name)) |array| {
            try array.append(allocator, .{
                .listener = @as(*anyopaque, @ptrCast(listener)),
                .callback = @as(EventCallback, @ptrCast(callback)),
            });
        } else {
            std.log.warn("Trying to listen to a not registered event type {s}", .{name});
        }
    }

    pub fn broadcast(self: *EventBus, comptime T: type, sender: ?*anyopaque, data: T) void {
        const name = @typeName(T);

        if (self.eventTypes.getPtr(name)) |array| {
            for (array.items) |item| {
                item.callback(item.listener, sender, @as(*const anyopaque, @ptrCast(&data)));
            }
        } else {
            std.log.warn("Trying to broadcast to a not registered event type {s}", .{name});
        }
    }

    pub const ViewError = error{
        UnknowEvent,
    };

    pub fn View(comptime T: type) type {
        return struct {
            const Self = @This();

            parent: *EventBus,
            listeners: *ListenerArray,

            pub fn listen(self: *Self, allocator: std.mem.Allocator, listener: anytype, callback: anytype) !void {
                try self.listeners.append(allocator, .{
                    .listener = @as(*anyopaque, @ptrCast(listener)),
                    .callback = @as(EventCallback, @ptrCast(callback)),
                });
            }

            pub fn broadcast(self: *Self, sender: ?*anyopaque, data: T) void {
                for (self.listeners.items) |item| {
                    item.callback(item.listener, sender, @ptrCast(&data));
                }
            }
        };
    }

    pub fn getView(self: *EventBus, comptime T: type) ViewError!View(T) {
        const name = @typeName(T);

        if (self.eventTypes.getPtr(name)) |array| {
            return View(T){ .parent = self, .listeners = array };
        } else {
            std.log.warn("Trying to get a view to a not registered event type {s}", .{name});
            return error.UnknowEvent;
        }
    }
};
