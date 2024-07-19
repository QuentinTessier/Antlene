const std = @import("std");
const ecs = @import("ecs");
const Pipeline = @import("../../Pipeline.zig");
const InputSingleton = @import("../Singletons/InputSingleton.zig");

const ActionLogic = @import("../Components/ConditionalLogic.zig").ActionLogic;

pub const ActionLogicSystemDescription = @This();

pub const Name = "ActionLogicSystem";

pub const Includes = .{ActionLogic};
pub const Excludes = .{};

pub const Components = struct {
    logic: ActionLogic,
};

pub const Singletons = struct {
    inputSingleton: InputSingleton,
};

pub const PipelineStep: Pipeline.PipelineStep = .OnPreFrameUpdate;
pub const Priority: i32 = 0;

pub fn each(registry: *ecs.Registry, e: ecs.Entity, comps: Components, singletons: Singletons) !void {
    const inputSingleton = singletons.inputSingleton;

    if (inputSingleton.actions.get(comps.logic.actionName)) |action| {
        if (action.result) {
            comps.logic.logic(registry, e);
        }
    }
}
