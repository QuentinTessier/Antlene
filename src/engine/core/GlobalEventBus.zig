const std = @import("std");
const EventBus = @import("EventHandling/EventBus.zig").EventBus;

var initialized: bool = false;
var a: std.mem.Allocator = undefined;
var eventbus: *EventBus = undefined;

pub fn init(allocator: std.mem.Allocator) !void {
    if (initialized) return;
    a = allocator;
    eventbus = try allocator.create(EventBus);
    eventbus.* = EventBus{};
    initialized = true;
}

pub fn deinit(allocator: std.mem.Allocator) void {
    _ = allocator;
    if (!initialized) return;
    eventbus.deinit(a);
    a.destroy(eventbus);
}

// Type as Event -> Might need to add a little bit of @typeName processing into it (demangle ...)
pub fn register(comptime T: type) !void {
    return eventbus.register(a, T);
}

pub fn listen(comptime T: type, listener: anytype, callback: anytype) !void {
    return eventbus.listen(a, T, listener, callback);
}

pub fn broadcast(comptime T: type, sender: ?*anyopaque, data: T) void {
    eventbus.broadcast(T, sender, data);
}
