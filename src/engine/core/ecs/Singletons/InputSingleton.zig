const std = @import("std");
const ecs = @import("ecs");
const WindowEvents = @import("AntleneWindowSystem").Events;
const Window = @import("AntleneWindowSystem");

pub const Action = @import("../../Events/Action.zig");
const Pipeline = @import("../../Pipeline.zig");

pub const InputSingleton = @This();

// TODO: Mouse input

pub const KeyState = enum(u8) {
    Pressed,
    Released,
    Up,
    Down,
};

keyboardState: std.EnumArray(WindowEvents.KeyCode, KeyState) = std.EnumArray(WindowEvents.KeyCode, KeyState).initFill(.Up),
actions: std.StringArrayHashMap(Action),

pub fn init(allocator: std.mem.Allocator) InputSingleton {
    return .{
        .actions = std.StringArrayHashMap(Action).init(allocator),
    };
}

pub fn setup(_: *InputSingleton) !void {
    try Pipeline.register(.OnFrameStart, .{
        .callback = &OnFrameStart,
        .prio = 0,
    });
}

pub fn deinit(self: *InputSingleton) void {
    self.actions.deinit();
}

pub fn OnFrameStart(registry: *ecs.Registry) !void {
    var self = registry.singletons().get(InputSingleton);

    for (&self.keyboardState.values, 0..) |value, i| {
        const key = std.EnumArray(WindowEvents.KeyCode, KeyState).Indexer.keyForIndex(i);
        const isDown = Window.getKeyState(key);
        const newValue: KeyState = switch (value) {
            .Up => if (isDown) .Pressed else .Up,
            .Down => if (!isDown) .Released else .Down,
            .Pressed => if (!isDown) .Released else .Down,
            .Released => if (!isDown) .Up else .Pressed,
        };
        self.keyboardState.set(key, newValue);
    }

    for (self.actions.values()) |*action| {
        action.update(self);
    }
}

pub fn isKey(self: *const InputSingleton, state: KeyState, keycode: WindowEvents.KeyCode) bool {
    const current_state = self.keyboardState.get(keycode);
    return current_state == state;
}

pub fn isKeyPressed(self: *const InputSingleton, keycode: WindowEvents.KeyCode) bool {
    return self.isKey(.Pressed, keycode);
}

pub fn isKeyReleased(self: *const InputSingleton, keycode: WindowEvents.KeyCode) bool {
    return self.isKey(.Released, keycode);
}

pub fn isKeyUp(self: *const InputSingleton, keycode: WindowEvents.KeyCode) bool {
    return self.isKey(.Up, keycode);
}

pub fn isKeyDown(self: *const InputSingleton, keycode: WindowEvents.KeyCode) bool {
    return self.isKey(.Down, keycode);
}

pub fn createAction(self: *InputSingleton, name: []const u8, action: Action) !void {
    try self.actions.put(name, action);
}
