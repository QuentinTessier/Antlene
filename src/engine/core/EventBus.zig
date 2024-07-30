const std = @import("std");
const EventBusGeneric = @import("Events/EventBus.zig").EventBus;
const Events = @import("AntleneWindowSystem").Events;
const Memory = @import("Memory.zig");

const TEventBus = EventBusGeneric(&.{Events.KeyEvent});

pub var _eventBus: *TEventBus = undefined;

pub fn init() !void {
    _eventBus = try Memory.Allocator.create(TEventBus);
    _eventBus.* = TEventBus.init(Memory.Allocator);
}

pub fn deinit() void {
    _eventBus.deinit();
    Memory.Allocator.destroy(_eventBus);
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
