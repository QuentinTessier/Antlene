const std = @import("std");
const WindowEvents = @import("AntleneWindowSystem").Events;
const InputSingleton = @import("../ecs/Singletons/InputSingleton.zig");

pub const Mapping = union(enum(u32)) {
    key: struct {
        code: WindowEvents.KeyCode,
        check: *const fn (code: WindowEvents.KeyCode, *const InputSingleton) bool,
    },
    mouseButton: struct {
        code: WindowEvents.MouseButton,
        check: *const fn (code: WindowEvents.KeyCode, *const InputSingleton) bool,
    },
};

pub const Action = @This();

mappings: []const Mapping,
result: bool = false,

pub fn update(self: *Action, inputSingleton: *const InputSingleton) void {
    self.result = false;
    for (self.mappings) |m| {
        switch (m) {
            .key => |keyMapping| {
                if (keyMapping.check(keyMapping.code, inputSingleton)) {
                    self.result = true;
                }
            },
            else => {},
        }
    }
}

pub fn DefaultHandlerKeyPressed(code: WindowEvents.KeyCode, inputSingleton: *const InputSingleton) bool {
    return inputSingleton.isKeyPressed(code);
}
