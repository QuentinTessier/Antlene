const std = @import("std");
const rl = @import("raylib");
const ecs = @import("zflecs");

pub const SpriteRendererSystem = @This();

const Transform = @import("../Components/Transform.zig");
const SpriteRenderer = @import("../Components/SpriteRenderer.zig");
const AtlasStorage = @import("../Components.zig").AtlasStorage;

fn Routine(it: *ecs.iter_t) callconv(.C) void {
    while (ecs.iter_next(it)) {
        for (0..it.count()) |i| {
            if (ecs.field(it, Transform, 1)) |transforms| {
                const currentTransform = @as(Transform, transforms[i]);
                if (ecs.field(it, SpriteRenderer, 2)) |renderers| {
                    const currentRenderer = @as(SpriteRenderer, renderers[i]);
                    const actualOrigin = currentRenderer.origin * currentTransform.scale;
                    if (currentRenderer.animation) |hasAnimation| {
                        const atlases = @as(?*const AtlasStorage, ecs.get(it.world, ecs.id(AtlasStorage), AtlasStorage)) orelse unreachable;
                        if (atlases.get(hasAnimation.name)) |atlas| {
                            const region = atlas.regions.items[hasAnimation.index];
                            rl.DrawTexturePro(
                                atlas.texture.handle,
                                .{
                                    .x = region[0],
                                    .y = region[1],
                                    .width = region[2],
                                    .height = region[3],
                                },
                                .{
                                    .x = currentTransform.position[0],
                                    .y = currentTransform.position[1],
                                    .width = currentTransform.scale[0],
                                    .height = currentTransform.scale[1],
                                },
                                .{ .x = actualOrigin[0], .y = actualOrigin[1] },
                                currentTransform.rotation,
                                .{
                                    .r = currentRenderer.tint[0],
                                    .g = currentRenderer.tint[1],
                                    .b = currentRenderer.tint[2],
                                    .a = currentRenderer.tint[3],
                                },
                            );
                        }
                    } else {
                        rl.DrawRectanglePro(
                            .{
                                .x = currentTransform.position[0],
                                .y = currentTransform.position[1],
                                .width = currentTransform.scale[0],
                                .height = currentTransform.scale[1],
                            },
                            .{ .x = actualOrigin[0], .y = actualOrigin[1] },
                            currentTransform.rotation,
                            .{
                                .r = currentRenderer.tint[0],
                                .g = currentRenderer.tint[1],
                                .b = currentRenderer.tint[2],
                                .a = currentRenderer.tint[3],
                            },
                        );
                    }
                }
            }
        }
    }
}

pub fn addSystemDescriptionToWorld(world: *ecs.world_t) void {
    var system_desc = ecs.system_desc_t{};
    system_desc.run = Routine;
    system_desc.query.filter.terms[0] = .{ .id = ecs.id(Transform), .inout = .In };
    system_desc.query.filter.terms[1] = .{ .id = ecs.id(SpriteRenderer), .oper = ecs.oper_kind_t.Optional, .inout = .In };
    ecs.SYSTEM(world, "RendererSystem", ecs.PostUpdate, &system_desc);
}
