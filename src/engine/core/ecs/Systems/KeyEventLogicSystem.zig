const std = @import("std");
const ecs = @import("ecs");
const Pipeline = @import("../../Pipeline.zig");
const InputSingleton = @import("../Singletons/InputSingleton.zig");

const KeyEventLogic = @import("../Components/ConditionalLogic.zig").KeyEventLogic;

pub const KeyEventLogicSystemDescription = @This();

pub const Includes = .{KeyEventLogic};
pub const Excludes = .{};

pub const Components = struct {
    logic: KeyEventLogic,
};

pub const Singletons = struct {
    inputSingleton: InputSingleton,
};

pub const PipelineStep: Pipeline.PipelineStep = .OnPreFrameUpdate;
pub const Priority: i32 = 0;

pub fn each(registry: *ecs.Registry, _: ecs.Entity, comps: Components, singletons: Singletons) !void {
    const inputSingleton = singletons.inputSingleton;

    if (inputSingleton.isKey(comps.logic.state, comps.logic.keycode)) {
        comps.logic.logic(registry);
    }
}
