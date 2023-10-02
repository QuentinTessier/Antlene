pub const std = @import("std");

pub const Application = struct {
    name: [*:0]const u8,
    version: u32,

    pub fn init(name: [*:0]const u8, version: u32) Application {
        return .{ .name = name, .version = version };
    }
};

pub const ApplicationInformation = struct {
    name: [*:0]const u8,
    version: u32,
    gameInit: *const fn (*Application) anyerror!void,
};
