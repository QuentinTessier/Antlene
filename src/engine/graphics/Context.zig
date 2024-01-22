const std = @import("std");
const World = @import("../Engine.zig").World;
pub const Camera = @import("Camera.zig").FlyingCamera;
const glGetProcAddress = @import("../Engine.zig").glGetProcAddress;

pub const Api = enum {
    OpenGL,
};

pub usingnamespace switch (Api.OpenGL) {
    inline .OpenGL => struct {
        const gl = @import("gl");
        pub const GenericMesh = @import("gl/Mesh.zig").Mesh;
        pub const DefaultVertex = @import("gl/Mesh.zig").DefaultVertex;
        pub const Mesh = GenericMesh(DefaultVertex);
        pub const Cube = @import("gl/Mesh.zig").cube;

        pub const Texture = @import("gl/Texture.zig");
        pub const ShaderProgram = @import("gl/Shader.zig");

        pub const UniformBuffer = @import("gl/UniformBuffer.zig").UniformBuffer;

        pub const name = .graphic_context;
        const Module = World.Mod(@This());

        // TODO: Entity should be able to refer the same mesh, this is not implemented yet in mach-ecs
        pub const components = struct {
            pub const mesh = Mesh;
            pub const camera = Camera;
        };

        pub fn init(_: *World) !void {
            try gl.load(void{}, glGetProcAddress);
        }

        pub const local = struct {
            pub fn setClearColor(_: *World, color: @Vector(4, f32)) !void {
                gl.clearColor(color[0], color[1], color[2], color[3]);
            }

            pub fn clearScreen(_: *World) !void {
                gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
            }
        };
    },
};
