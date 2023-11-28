const std = @import("std");
const ecs = @import("zflecs");

//fn DefineWorld(world: *ecs.world_t) void {
//    inline for (Systems.RendererSystem.ComponentTypes) |t| {
//        ecs.COMPONENT(world, t);
//    }
//    Systems.RendererSystem.QueryDescription(world);
//    Systems.UpdateSystem.QueryDescription(world);
//}

pub const Scene = struct {
    name: []const u8,

    world: *ecs.world_t,

    internal_free: *const fn (*Scene, std.mem.Allocator) void,

    onCreate: ?*const fn (*Scene, std.mem.Allocator) anyerror!void = null,
    onDestroy: ?*const fn (*Scene, std.mem.Allocator) anyerror!void = null,

    onUpdate: ?*const fn (*Scene, f32) void = null,
    onDraw: ?*const fn (*Scene) void = null,

    pub fn EnsureTypeDefinition(comptime SceneType: type) void {
        const fieldEnum = std.meta.FieldEnum(SceneType);
        if (!@hasField(SceneType, "base")) {
            @compileError("Expecting " ++ @typeName(SceneType) ++ " to have a field of type \"Scene\" with name \"base\".");
        } else if (std.meta.fieldInfo(SceneType, fieldEnum.base).type != Scene) {
            @compileError("EnsureScene(" ++ @typeName(SceneType) ++ ") expects the given structure to have a field with name \"base\" of type \"Scene\".");
        } else if (!@hasDecl(SceneType, "init")) {
            @compileError("EnsureScene(" ++ @typeName(SceneType) ++ ") expects the given structure to have a method of type \"*const fn (*SceneType) void\" with name \"init\".");
        }
    }

    pub fn createScene(comptime T: type, name: []const u8, allocator: std.mem.Allocator) !*T {
        var ptr = try allocator.create(T);

        ptr.base = .{
            .name = name,
            .world = ecs.init(), // TODO: Define base components & systems
            .internal_free = struct {
                fn free(s: *Scene, a: std.mem.Allocator) void {
                    const parent = @fieldParentPtr(T, "base", s);
                    a.destroy(parent);
                }
            }.free,
            .onCreate = if (@hasDecl(T, "onCreate")) &T.onCreate else null,
            .onDestroy = if (@hasDecl(T, "onDestroy")) &T.onDestroy else null,
            .onUpdate = if (@hasDecl(T, "onUpdate")) &T.onUpdate else null,
            .onDraw = if (@hasDecl(T, "onDraw")) &T.onDraw else null,
        };
        T.init(ptr);
        return ptr;
    }

    pub fn deinit(self: *Scene, allocator: std.mem.Allocator) void {
        _ = ecs.fini(self.world);
        self.internal_free(self, allocator);
    }

    pub fn draw(self: *Scene) void {
        if (self.onDraw) |drawFn| {
            drawFn(self);
        }
    }
};
