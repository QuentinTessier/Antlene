const std = @import("std");
pub const Application = @import("Core/Application.zig").Application;

pub fn entry(applicationParams: Application.Parameters) anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    var application = try Application.init(allocator, applicationParams);
    defer application.deinit();

    try application.run();
}
