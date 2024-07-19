const std = @import("std");
const Antlene = @import("antlene");

pub const applicationCreateInfo: Antlene.Application.ApplicationCreateInfo = .{
    .name = "Testbed",
    .width = 1280,
    .height = 720,
    .initialize = initialize,
};

pub fn logic(registry: *Antlene.ecs.Registry) void {
    const app = registry.singletons().get(*Antlene.Application).*;

    app.close();
}

pub fn initialize(app: *Antlene.Application) !void {
    const e = app.registry.create();

    app.registry.add(e, Antlene.ECS.Components.ConditionalLogic.KeyEventLogic{
        .keycode = .Escape,
        .state = .Pressed,
        .logic = &logic,
    });
}
