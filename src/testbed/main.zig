const std = @import("std");
const Antlene = @import("antlene");

pub const applicationCreateInfo: Antlene.Application.ApplicationCreateInfo = .{
    .name = "Testbed",
    .width = 1280,
    .height = 720,
    .initialize = initialize,
};

pub fn logic(registry: *Antlene.ecs.Registry) void {
    const app = registry.singletons().get(*Antlene.Application);
    var textureRegistry: *Antlene.ECS.Singleton.TextureRegistry = registry.singletons().get(Antlene.ECS.Singleton.TextureRegistry);
    const handle: ?Antlene.ECS.Singleton.TextureRegistry.TextureHandle = textureRegistry.loadTexture(app.*.allocator, "./assets/Materials/DiffuseColor.png", 3) catch blk: {
        std.log.err("Failed to load texture !", .{});
        break :blk null;
    };

    const sprite1 = registry.create();
    registry.add(sprite1, Antlene.ECS.Components.Transform{
        .position = .{ 50, 50, 0.0 },
        .scale = .{ 100, 100 },
    });
    registry.add(sprite1, Antlene.ECS.Components.Sprite{
        .handle = handle,
    });

    const sprite2 = registry.create();
    registry.add(sprite2, Antlene.ECS.Components.Transform{
        .position = .{ -50, -50, 0.0 },
        .scale = .{ 100, 100 },
    });
    registry.add(sprite2, Antlene.ECS.Components.Sprite{
        .color = .{ 1, 0, 0, 1 },
    });
}

pub fn initialize(app: *Antlene.Application) !void {
    const e = app.registry.create();

    app.registry.add(e, Antlene.ECS.Components.ConditionalLogic.KeyEventLogic{
        .keycode = .A,
        .state = .Pressed,
        .logic = &logic,
    });

    const camera = app.registry.create();
    app.registry.add(camera, Antlene.ECS.Components.Camera{});
    app.registry.add(camera, @as(Antlene.ECS.Components.ActiveCamera, 0));
}
