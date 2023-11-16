const std = @import("std");
const antlene = @import("antlene");

const TestbedApplicationInformation = antlene.ApplicationInformation{
    .name = "Testbed",
    .version = antlene.Version.make(0, 1, 0),
    .gameInit = &init,
    .gameUpdate = &update,
};

pub fn getApplicationInformation() antlene.ApplicationInformation {
    return TestbedApplicationInformation;
}

const GameState = struct {
    name: []u8,
};

pub fn init(app: *antlene.Application) anyerror!void {
    std.log.info("Init application {}.{}.{} !", .{ antlene.Version.getMajor(app.version), antlene.Version.getMinor(app.version), antlene.Version.getPatch(app.version) });
    std.log.info("Engine is running on {s}", .{app.getGraphicAPIVersion()});
}

pub const TestBedScene = struct {
    base: antlene.SceneBase,

    pub fn init(allocator: std.mem.Allocator) anyerror!void {
        _ = allocator;
        std.log.info("Init scene");
    }

    pub fn onUpdate(base: *antlene.SceneBase, deltaTime: f64) anyerror!void {
        _ = deltaTime;
        _ = base;
    }

    pub fn onDraw(base: *antlene.SceneBase) void {
        _ = base;
        antlene.Renderer2D.begin(antlene.ApplicationHandle.mainCamera);

        const sprite = antlene.Renderer2D.Sprite{
            .position = .{ 0, 0 },
            .size = .{ 150, 150 },
            .color = .{ 0, 1, 1, 1 },
        };

        const sprite1 = antlene.Renderer2D.Sprite{
            .position = .{ 0, 0 },
            .size = .{ 500, 500 },
            .color = .{ 1, 0, 1, 1 },
        };

        antlene.Renderer2D.drawSprite(sprite1);
        antlene.Renderer2D.drawSprite(sprite);

        antlene.Renderer2D.end();
    }
};

pub fn update(app: *antlene.Application, deltaTime: f64) anyerror!void {
    _ = deltaTime;
    antlene.Renderer2D.begin(app.mainCamera);

    const sprite = antlene.Renderer2D.Sprite{
        .position = .{ 0, 0 },
        .size = .{ 150, 150 },
        .color = .{ 0, 1, 1, 1 },
    };

    const sprite1 = antlene.Renderer2D.Sprite{
        .position = .{ 0, 0 },
        .size = .{ 500, 500 },
        .color = .{ 1, 0, 1, 1 },
    };

    antlene.Renderer2D.drawSprite(sprite1);
    antlene.Renderer2D.drawSprite(sprite);

    antlene.Renderer2D.end();
}
