const std = @import("std");
const ecs = @import("zflecs");

pub const Transform = @import("./Components/Transform.zig");
pub const SpriteRenderer = @import("./Components/SpriteRenderer.zig");
pub const SpriteAnimator = @import("./Components/SpriteAnimator.zig");
pub const Atlas = @import("./Components/Atlas.zig");

pub const AtlasStorage = std.StringHashMapUnmanaged(Atlas);

pub const Antlene = @import("../../Antlene.zig");

const SpriteRendererSystem = @import("./Systems/SpriteRendererSystem.zig");

pub const ComponentTypes = [_]type{
    Transform,
    SpriteRenderer,
    SpriteAnimator,
    AtlasStorage,
};

pub fn RegisterComponents(world: *ecs.world_t) void {
    inline for (ComponentTypes) |t| {
        std.log.info("Registering component of type {s}", .{@typeName(t)});
        ecs.COMPONENT(world, t);
    }
}

pub fn DefineSingleton(world: *ecs.world_t) void {
    _ = ecs.set(world, ecs.id(AtlasStorage), AtlasStorage, .{});

    var observer_desc = std.mem.zeroes(ecs.observer_desc_t);
    observer_desc.filter.terms[0] = std.mem.zeroInit(ecs.term_t, .{ .id = ecs.id(AtlasStorage), .src = .{ .id = ecs.id(AtlasStorage) } });
    observer_desc.events[0] = ecs.OnRemove;
    observer_desc.run = struct {
        pub fn Routine(it: *ecs.iter_t) callconv(.C) void {
            while (ecs.iter_next(it)) {
                for (0..it.count()) |i| {
                    if (ecs.field(it, AtlasStorage, 1)) |storages| {
                        var ite = storages[i].iterator();
                        while (ite.next()) |item| {
                            item.value_ptr.deinit(Antlene.ApplicationHandle.allocator);
                        }
                        storages[i].deinit(Antlene.ApplicationHandle.allocator);
                    }
                }
            }
        }
    }.Routine;
    ecs.OBSERVER(world, "AtlasStorageDestructor", &observer_desc);
}

pub fn RegisterSystems(world: *ecs.world_t) void {
    SpriteRendererSystem.addSystemDescriptionToWorld(world);
}
