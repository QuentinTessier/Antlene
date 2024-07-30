const std = @import("std");
const Antlene = @import("antlene");

pub const applicationCreateInfo: Antlene.Application.ApplicationCreateInfo = .{
    .name = "Testbed",
    .width = 1280,
    .height = 720,
    .initialize = initialize,
};

const GameLogger = std.log.scoped(.Game);

pub fn move_camera(registry: *Antlene.ecs.Registry, entity: Antlene.ecs.Entity) void {
    var camera = registry.get(Antlene.Components.Camera, entity);

    camera.target[1] += 0.5;
}

var orientation: f32 = 0;
var rng: std.Random = undefined;

fn change_orientation(registry: *Antlene.ecs.Registry, _: Antlene.ecs.Entity) void {
    if (orientation < 270) {
        orientation += 90;
    } else {
        orientation = 0;
    }

    const rotation = Antlene.Math.Mat4x4.rotateZ(Antlene.Math.degreesToRadians(orientation));
    Antlene.Application.RendererFrontend.updateOritentation(rotation);

    var view = registry.view(.{Antlene.Components.Chunk}, .{});
    var ite = view.entityIterator();

    while (ite.next()) |e| {
        var chunk: *Antlene.Components.Chunk = view.get(e);
        const rotated = Antlene.Math.Mat4x4.mulVec(rotation, .{ @floatFromInt(chunk.id[0]), @floatFromInt(chunk.id[1]), 0.0, 1.0 });

        chunk.worldPosition = Antlene.Components.Chunk.getWorldPosition(.{ @intFromFloat(@round(rotated[0])), @intFromFloat(@round(rotated[1])) });
        chunk.gpuBuffer.?.updateData(std.mem.sliceAsBytes(&[2]f32{ chunk.worldPosition[0], chunk.worldPosition[1] }), 0);
    }
}

fn fillChunk(allocator: std.mem.Allocator, tiles: *std.ArrayListUnmanaged(Antlene.Components.Chunk.Tile), id: @Vector(2, i32), seed: i32) !void {
    const gen = Antlene.Noise.FnlGenerator{
        .seed = seed,
        .frequency = 0.01,
        .noise_type = .opensimplex2,
        .rotation_type3 = .none,
        .fractal_type = .none,
        .octaves = 3,
        .lacunarity = 2.0,
        .gain = 0.5,
        .weighted_strength = 0.0,
        .ping_pong_strength = 2.0,
        .cellular_distance_func = .euclideansq,
        .cellular_return_type = .distance,
        .cellular_jitter_mod = 1.0,
        .domain_warp_type = .opensimplex2,
        .domain_warp_amp = 1.0,
    };

    for (0..Antlene.Components.Chunk.ChunkSize) |x| {
        for (0..Antlene.Components.Chunk.ChunkSize) |y| {
            const X = @as(i32, @intCast(x)) + id[0] * 32;
            const Y = @as(i32, @intCast(y)) + id[1] * 32;
            const noise_value = gen.noise2(@floatFromInt(X), @floatFromInt(Y));
            const iLevel: usize = @intFromFloat(@abs(1 - noise_value) * 16);
            for (0..iLevel) |z| {
                const tile = Antlene.Components.Chunk.Tile{
                    .x = @intCast(x),
                    .y = @intCast(y),
                    .z = @intCast(z),
                    .id = 0,
                };
                try tiles.append(allocator, tile);
            }
        }
    }
}

fn updateChunk(registry: *Antlene.ecs.Registry, _: Antlene.ecs.Entity) void {
    var view = registry.view(.{Antlene.Components.Chunk}, .{});
    var ite = view.entityIterator();

    const seed = rng.int(i32);
    while (ite.next()) |e| {
        var chunk: *Antlene.Components.Chunk = view.get(e);

        chunk.tiles.clearRetainingCapacity();
        fillChunk(registry.singletons().get(*Antlene.Application).*.allocator, &chunk.tiles, chunk.id, seed) catch {
            std.log.err("Failed to fill chunk", .{});
        };
        if (chunk.gpuBuffer) |*buffer| {
            if ((chunk.tiles.items.len * @sizeOf(Antlene.Components.Chunk.Tile) + 2 * @sizeOf(f32)) != buffer.size) {
                buffer.deinit();
                var newBuffer = Antlene.Graphics.Resources.CreateBuffer(
                    null,
                    .{ .size = @sizeOf(f32) * 2 + @sizeOf(Antlene.Components.Chunk.Tile) * chunk.tiles.items.len },
                    .{ .dynamic = true },
                );
                newBuffer.updateData(std.mem.sliceAsBytes(&[2]f32{ chunk.worldPosition[0], chunk.worldPosition[1] }), 0);
                newBuffer.updateData(std.mem.sliceAsBytes(chunk.tiles.items), @sizeOf(f32) * 2);
                chunk.gpuBuffer = newBuffer;
            } else {
                buffer.updateData(std.mem.sliceAsBytes(chunk.tiles.items), @sizeOf(f32) * 2);
            }
        }
    }
}

fn createChunk(application: *Antlene.Application, id: @Vector(2, i32), seed: i32) !void {
    const eChunk1 = application.registry.create();
    application.registry.add(eChunk1, try Antlene.Components.Chunk.init(id));
    const chunk: *Antlene.Components.Chunk = application.registry.get(Antlene.Components.Chunk, eChunk1);

    try fillChunk(application.allocator, &chunk.tiles, id, seed);
    chunk.gpuBuffer = Antlene.Graphics.Resources.CreateBuffer(
        null,
        .{ .size = @sizeOf(f32) * 2 + @sizeOf(Antlene.Components.Chunk.Tile) * chunk.tiles.items.len },
        .{ .dynamic = true },
    );

    chunk.gpuBuffer.?.updateData(std.mem.sliceAsBytes(&[2]f32{ chunk.worldPosition[0], chunk.worldPosition[1] }), 0);
    chunk.gpuBuffer.?.updateData(std.mem.sliceAsBytes(chunk.tiles.items), @sizeOf(f32) * 2);
}

pub fn initialize(application: *Antlene.Application) !void {
    var prng = std.rand.DefaultPrng.init(blk: {
        var s: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&s));
        break :blk s;
    });
    rng = prng.random();

    const camera = application.registry.create();
    application.registry.add(camera, Antlene.Components.Camera{
        .zoom = 0.5,
    });
    application.registry.addTyped(Antlene.Components.ActiveCamera, camera, 0);
    application.registry.add(camera, Antlene.Components.ConditionalLogic.KeyEventLogic{
        .keycode = .Down,
        .state = .Down,
        .logic = &move_camera,
    });

    const a = application.registry.create();
    application.registry.add(a, Antlene.Components.ConditionalLogic.KeyEventLogic{
        .keycode = .Space,
        .state = .Released,
        .logic = &change_orientation,
    });

    const b = application.registry.create();
    application.registry.add(b, Antlene.Components.ConditionalLogic.KeyEventLogic{
        .keycode = .P,
        .state = .Released,
        .logic = &updateChunk,
    });

    const chunks: [9]@Vector(2, i32) = .{
        .{ -1, -1 }, .{ 0, -1 }, .{ 1, -1 },
        .{ -1, 0 },  .{ 0, 0 },  .{ 1, 0 },
        .{ -1, 1 },  .{ 0, 1 },  .{ 1, 1 },
    };

    const seed = rng.int(i32);
    for (chunks) |c| {
        try createChunk(application, c, seed);
    }
}
