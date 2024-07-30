const std = @import("std");
const ecs = @import("ecs");

const Memory = @import("Memory.zig");

const PriorityList = @import("../zig/PriorityList.zig").PriorityList(StepExec, .{ .field = .prio, .lessThan = struct {
    pub fn inlineFn(a: StepExec, b: StepExec) bool {
        return a.prio < b.prio;
    }
}.inlineFn });

pub const PipelineStep = enum(u32) {
    OnFrameStart, // Mostly engine tasks (IO, destroying unused ressources, ...)
    OnPreFrameUpdate, // Prepare for update
    OnFrameUpdate, // Update module
    OnFrameValidate, // Prepare for rendering (build rendering tasks)
    OnFrameEnd, // Store data & clean frame info

    ReleaseResources,
};

pub const PipelineInfo = struct {
    allocator: std.mem.Allocator,
};

pub const StepExec = struct {
    prio: i32,
    callback: *const fn (*ecs.Registry) anyerror!void,
};

var _steps: std.EnumArray(PipelineStep, std.ArrayListUnmanaged(StepExec)) = std.EnumArray(PipelineStep, std.ArrayListUnmanaged(StepExec)).initFill(.{});

pub fn init() void {}

pub fn deinit() void {
    var ite = _steps.iterator();
    while (ite.next()) |entry| {
        entry.value.deinit(Memory.Allocator);
    }
}

pub fn register(step: PipelineStep, e: StepExec) std.mem.Allocator.Error!void {
    const s = _steps.getPtr(step);
    const index = PriorityList.findIndex(s.items, e);
    try s.insert(Memory.Allocator, index, e);
}

pub fn unregister(step: PipelineStep, e: StepExec) void {
    var list = _steps.getPtr(step);
    var index: ?usize = null;
    for (list.items, 0..) |item, i| {
        if (std.mem.eql(u8, item.moduleName, e.moduleName) and item.callback == e.callback) {
            index = i;
        }
    }
    if (index) |i| {
        list.orderedRemove(i);
    }
}

pub fn exec(registry: *ecs.Registry, step: PipelineStep) !void {
    const execList: std.ArrayListUnmanaged(StepExec) = _steps.get(step);

    for (execList.items) |toExec| {
        try toExec.callback(registry);
    }
}
