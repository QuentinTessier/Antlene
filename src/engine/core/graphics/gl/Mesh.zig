const std = @import("std");
const gl = @import("gl");

pub const AttributeDescription = struct {
    size: usize,
    type: gl.GLenum,
    normalized: bool,
};

pub const DefaultVertex = struct {
    position: @Vector(3, f32),
    normal: @Vector(3, f32),
    texCoords: @Vector(2, f32),

    const attributes = [_]AttributeDescription{
        .{ .size = 3, .type = gl.FLOAT, .normalized = false },
        .{ .size = 3, .type = gl.FLOAT, .normalized = false },
        .{ .size = 2, .type = gl.FLOAT, .normalized = false },
    };
};

pub fn Mesh(comptime VertexType: type) type {
    if (@typeInfo(VertexType) != .Struct) @panic("Must be struct");
    if (!@hasDecl(VertexType, "attributes")) @panic("Declare attribute description");

    return struct {
        pub const Vertex = VertexType;

        vertices: []const VertexType,
        indices: []const u32,

        voa: u32 = 0,
        vob: u32 = 0,
        eob: u32 = 0,

        pub fn init(vertices: []const VertexType, indices: []const u32) @This() {
            var self: @This() = .{ .vertices = vertices, .indices = indices };
            gl.genVertexArrays(1, @ptrCast(&self.voa));
            gl.genBuffers(1, @ptrCast(&self.vob));
            gl.genBuffers(1, @ptrCast(&self.eob));

            gl.bindVertexArray(self.voa);

            gl.bindBuffer(gl.ARRAY_BUFFER, self.vob);
            gl.bufferData(gl.ARRAY_BUFFER, @intCast(vertices.len * @sizeOf(VertexType)), vertices.ptr, gl.STATIC_DRAW);

            gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, self.eob);
            gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, @intCast(indices.len * @sizeOf(u32)), indices.ptr, gl.STATIC_DRAW);

            const description = VertexType.attributes;

            const fields = std.meta.fields(VertexType);
            inline for (fields, 0..) |f, i| {
                const d = description[i];
                const offset: usize = @offsetOf(VertexType, f.name);
                gl.enableVertexAttribArray(@intCast(i));
                gl.vertexAttribPointer(
                    @intCast(i),
                    @intCast(d.size),
                    d.type,
                    if (d.normalized) gl.TRUE else gl.FALSE,
                    @sizeOf(VertexType),
                    @ptrFromInt(offset),
                );
            }
            gl.bindVertexArray(0);

            return self;
        }

        pub fn deinit(self: *@This()) void {
            gl.deleteVertexArrays(1, @ptrCast(&self.voa));
            gl.deleteBuffers(1, @ptrCast(&self.vob));
            gl.deleteBuffers(1, @ptrCast(&self.eob));
        }

        pub fn draw(self: @This()) void {
            gl.bindVertexArray(self.voa);
            gl.drawElements(gl.TRIANGLES, @intCast(self.indices.len), gl.UNSIGNED_INT, null);
            gl.bindVertexArray(0);
        }
    };
}
