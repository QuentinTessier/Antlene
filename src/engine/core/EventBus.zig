const std = @import("std");
const EventBusGeneric = @import("Events/EventBus.zig").EventBus;
const Events = @import("AntleneWindowSystem").Events;

const TEventBus = EventBusGeneric(&.{Events.KeyEvent});

pub var _eventBus: *TEventBus = undefined;

pub fn init(allocator: std.mem.Allocator) !void {
    _eventBus = try allocator.create(TEventBus);
    _eventBus.* = TEventBus.init(allocator);
}

pub fn deinit(allocator: std.mem.Allocator) void {
    _eventBus.deinit();
    allocator.destroy(_eventBus);
}

pub inline fn listen(comptime T: type, obj: anytype, callback: anytype) !void {
    return _eventBus.listen(T, obj, callback);
}

// Instantly run the callbacks
pub inline fn notify(event: anytype) void {
    _eventBus.notify(event);
}

pub inline fn postpone(event: anytype) !void {
    return _eventBus.postpone(event);
}

pub inline fn process() void {
    _eventBus.process();
}
