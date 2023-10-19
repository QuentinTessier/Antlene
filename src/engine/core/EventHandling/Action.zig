const std = @import("std");

const WindowEvent = @import("../Platform/Window.zig").WindowEvent;
const KeyCode = @import("../Platform/Window.zig").KeyCode;

const Trigger = union(enum(u32)) {
    key: struct {
        code: KeyCode,
        state: u32,
    },
};

const ActionData = union(enum(u32)) {
    digital: bool,
    float1: f32,
    float2: @Vector(2, f32),
};

pub const Action = struct {
    trigger: Trigger,
    value: ActionData,
    fn onWindowEvent(self: *Action, window: ?*anyopaque, event: WindowEvent) void {
        _ = window;
        switch (self.trigger) {
            .key => {
                switch (event) {
                    .keyDown => {},
                    .keyUp => {},
                    .keyRepeat => {},
                }
            },
        }
    }
};
