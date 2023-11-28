const std = @import("std");
const Antlene = @import("antlene");

pub const ApplicationParameters: Antlene.Application.Parameters = .{
    .name = "test",
    .version = 1,
    .init = &init,
    .windowInfo = .{
        .name = "test",
        .width = 1280,
        .height = 720,
    },
};

pub fn init(app: *Antlene.Application) anyerror!void {
    _ = app;
}
