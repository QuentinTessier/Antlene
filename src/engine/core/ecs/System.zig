const std = @import("std");
const ecs = @import("ecs");
const Pipeline = @import("../Pipeline.zig");

pub const KeyEventLogicSystemDescription = @import("./Systems/KeyEventLogicSystem.zig");

fn GatherSingletons(comptime SingletonCollection: type, registry: *ecs.Registry) SingletonCollection {
    if (SingletonCollection == void) {
        return void{};
    }
    const fields = std.meta.fields(SingletonCollection);
    var singletons: SingletonCollection = undefined;
    inline for (fields) |field| {
        const info = @typeInfo(field.type);
        switch (info) {
            .Pointer => |ptr| {
                const T = ptr.child;
                @field(singletons, field.name) = registry.singletons().get(T);
            },
            else => {
                const T = field.type;
                @field(singletons, field.name) = registry.singletons().getConst(T);
            },
        }
    }
    return singletons;
}

fn GatherComponentsMultiView(comptime ComponentCollection: type, view: anytype, entity: ecs.Entity) ComponentCollection {
    var comps: ComponentCollection = undefined;
    inline for (std.meta.fields(ComponentCollection)) |field| {
        const info = @typeInfo(field.type);
        switch (info) {
            .Pointer => |ptr| {
                const T = ptr.child;
                @field(comps, field.name) = view.get(T, entity);
            },
            else => {
                const T = field.type;
                @field(comps, field.name) = view.getConst(T, entity);
            },
        }
    }
    return comps;
}

fn GatherComponentsBasicView(comptime ComponentCollection: type, view: anytype, entity: ecs.Entity) ComponentCollection {
    var comps: ComponentCollection = undefined;
    inline for (std.meta.fields(ComponentCollection)) |field| {
        const info = @typeInfo(field.type);
        switch (info) {
            .Pointer => {
                @field(comps, field.name) = view.get(entity);
            },
            else => {
                @field(comps, field.name) = view.getConst(entity);
            },
        }
    }
    return comps;
}

pub fn MakeSystem(comptime Description: type) type {
    return struct {
        pub const PipelineStep: Pipeline.PipelineStep = Description.PipelineStep;
        pub const Priority: i32 = Description.Priority;

        pub fn execute(registry: *ecs.Registry) !void {
            var view = registry.view(Description.Includes, Description.Excludes);
            var ite = view.entityIterator();
            const singletons = GatherSingletons(Description.Singletons, registry);
            const isBasicView = Description.Includes.len == 1 and Description.Excludes.len == 0;
            while (ite.next()) |entity| {
                const components: Description.Components = switch (isBasicView) {
                    true => GatherComponentsBasicView(Description.Components, &view, entity),
                    false => GatherComponentsMultiView(Description.Components, &view, entity),
                };
                try @call(.auto, Description.each, .{ registry, entity, components, singletons });
            }
        }
    };
}

pub fn registerSystem(comptime System: type) !void {
    try Pipeline.register(System.PipelineStep, .{
        .callback = System.execute,
        .prio = System.Priority,
    });
}
