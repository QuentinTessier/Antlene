const std = @import("std");
const ecs = @import("ecs");
const WindowEvents = @import("AntleneWindowSystem").Events;
const KeyState = @import("../Singletons/InputSingleton.zig").KeyState;

pub const KeyEventLogic = struct {
    keycode: WindowEvents.KeyCode,
    state: KeyState,
    logic: *const fn (*ecs.Registry) void,
};
