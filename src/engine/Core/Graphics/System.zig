const std = @import("std");
const ecs = @import("zflecs");
const rl = @import("raylib");
const Utils = @import("Utils.zig");

const Sprite = @import("Sprite.zig");
pub const Layer = @import("Layer.zig").Layer;
const Components = @import("../Components.zig");

pub const RendererSystem = struct {
    pub const ComponentTypes = [_]type{ Components.Transform, Sprite, Layer };

    fn Routine(it: *ecs.iter_t) callconv(.C) void {
        const transforms = @as([]Components.Transform, ecs.field(it, Components.Transform, 1).?);
        const sprites = @as([]Sprite, ecs.field(it, Sprite, 2).?);

        for (0..it.count()) |i| {
            const screen_space = @shuffle(
                f32,
                transforms[i].position,
                transforms[i].scale,
                @Vector(4, i32){ 0, 1, -1, -2 },
            );
            switch (sprites[i].source) {
                .texture => |texture| {
                    rl.DrawTexturePro(
                        texture.handle,
                        Utils.toRectangle(sprites[i].region),
                        Utils.toRectangle(screen_space),
                        Utils.toVector2(sprites[i].origin),
                        transforms[i].rotation,
                        Utils.toColor(sprites[i].color),
                    );
                },
                .animation => |animation| {
                    sprites[i].region = animation.getRegionFromAtlas(null);
                    rl.DrawTexturePro(
                        animation.atlas.texture.handle,
                        Utils.toRectangle(sprites[i].region),
                        Utils.toRectangle(screen_space),
                        Utils.toVector2(sprites[i].origin * transforms[i].scale),
                        transforms[i].rotation,
                        Utils.toColor(sprites[i].color),
                    );
                },
                .none => {
                    rl.DrawRectanglePro(
                        Utils.toRectangle(screen_space),
                        Utils.toVector2(sprites[i].origin * transforms[i].scale),
                        transforms[i].rotation,
                        Utils.toColor(sprites[i].color),
                    );
                },
            }
        }
    }

    fn OrderLayer(_: ecs.entity_t, l1: *const Layer, _: ecs.entity_t, l2: *const Layer) callconv(.C) i32 {
        return @intFromBool(l1.* < l2.*);
    }

    pub fn QueryDescription(world: *ecs.world_t) void {
        var system_desc = ecs.system_desc_t{};
        system_desc.callback = &RendererSystem.Routine;
        system_desc.query.filter.terms[0] = .{ .id = ecs.id(Components.Transform) };
        system_desc.query.filter.terms[1] = .{ .id = ecs.id(Sprite) };
        system_desc.query.filter.terms[2] = .{ .id = ecs.id(Layer) };
        system_desc.query.order_by_component = ecs.id(Layer);
        system_desc.query.order_by = @ptrCast(&RendererSystem.OrderLayer);
        ecs.SYSTEM(world, "RendererSystem", ecs.OnStore, &system_desc);
    }
};
