const std = @import("std");
const rl = @import("raylib");
const rg = @import("raygui");

pub fn window(region: @Vector(4, f32), text: [:0]const u8) bool {
    return rg.GuiWindowBox(.{
        .x = region[0],
        .y = region[1],
        .width = region[2],
        .height = region[3],
    }, text) == 1;
}

pub fn group(region: @Vector(4, f32), text: [:0]const u8) bool {
    return rg.GuiWindowBox(.{
        .x = region[0],
        .y = region[1],
        .width = region[2],
        .height = region[3],
    }, text) == 1;
}

pub fn panel(region: @Vector(4, f32), text: [:0]const u8) bool {
    return rg.GuiWindowBox(.{
        .x = region[0],
        .y = region[1],
        .width = region[2],
        .height = region[3],
    }, text) == 1;
}
