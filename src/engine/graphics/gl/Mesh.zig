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

const CubeVertices = [_]DefaultVertex{
    .{ .position = .{ -1.0, -1.0, 1.0 }, .normal = .{ 0, 0, 0 }, .texCoords = .{ 0, 0 } },
    .{ .position = .{ 1.0, -1.0, 1.0 }, .normal = .{ 0, 0, 0 }, .texCoords = .{ 0, 0 } },
    .{ .position = .{ 1.0, 1.0, 1.0 }, .normal = .{ 0, 0, 0 }, .texCoords = .{ 0, 0 } },
    .{ .position = .{ -1.0, 1.0, 1.0 }, .normal = .{ 0, 0, 0 }, .texCoords = .{ 0, 0 } },
    .{ .position = .{ -1.0, -1.0, -1.0 }, .normal = .{ 0, 0, 0 }, .texCoords = .{ 0, 0 } },
    .{ .position = .{ 1.0, -1.0, -1.0 }, .normal = .{ 0, 0, 0 }, .texCoords = .{ 0, 0 } },
    .{ .position = .{ 1.0, 1.0, -1.0 }, .normal = .{ 0, 0, 0 }, .texCoords = .{ 0, 0 } },
    .{ .position = .{ -1.0, 1.0, -1.0 }, .normal = .{ 0, 0, 0 }, .texCoords = .{ 0, 0 } },
};

const CubeIndices = [_]u32{
    0, 1, 2,
    2, 3, 0,
    1, 5, 6,
    6, 2, 1,
    7, 6, 5,
    5, 4, 7,
    4, 0, 3,
    3, 7, 4,
    4, 5, 1,
    1, 0, 4,
    3, 2, 6,
    6, 7, 3,
};

const PlaneVertices = [_]DefaultVertex{
    .{ .position = .{ 1, 1, 0 }, .normal = .{ 0, 0, 1 }, .texCoords = .{ 0, 0 } },
    .{ .position = .{ 1, -1, 0 }, .normal = .{ 0, 0, 1 }, .texCoords = .{ 0, 0 } },
    .{ .position = .{ -1, -1, 0 }, .normal = .{ 0, 0, 1 }, .texCoords = .{ 0, 0 } },
    .{ .position = .{ -1, 1, 0 }, .normal = .{ 0, 0, 1 }, .texCoords = .{ 0, 0 } },
};

const PlaneIndices = [_]u32{
    0, 1, 3,
    1, 2, 3,
};

pub fn cube() Mesh(DefaultVertex) {
    return Mesh(DefaultVertex).init(&CubeVertices, &CubeIndices);
}

pub fn plane() Mesh(DefaultVertex) {
    return Mesh(DefaultVertex).init(&PlaneVertices, &PlaneIndices);
}

pub fn generateSphere(allocator: std.mem.Allocator, radius: f32, inLatitude: u32, inLongitude: u32) !struct { vertices: []DefaultVertex, indices: []u32 } {
    var vertices = std.ArrayList(DefaultVertex).init(allocator);
    const latitude = if (inLatitude < 2) 2 else inLatitude;
    const longitude = if (inLongitude < 3) 3 else inLongitude;

    const lengthInv = 1.0 / radius;

    const deltaLatitude = std.math.pi / @as(f32, @floatFromInt(latitude));
    const deltaLongitude = 2.0 * std.math.pi / @as(f32, @floatFromInt(longitude));
    var latitudeAngle: f32 = 0.0;
    var longitudeAngle: f32 = 0.0;
    {
        var i: u32 = 0;
        var j: u32 = 0;
        while (i <= latitude) : (i += 1) {
            latitudeAngle = std.math.pi * 0.5 - @as(f32, @floatFromInt(i)) * deltaLatitude;
            const xy = radius * std.math.cos(latitudeAngle);
            const z = radius * std.math.sin(latitudeAngle);
            while (j <= longitude) : (j += 1) {
                longitudeAngle = @as(f32, @floatFromInt(j)) * deltaLongitude;
                const position = @Vector(3, f32){ xy * std.math.cos(longitudeAngle), xy * std.math.sin(longitudeAngle), z };
                const vertex: DefaultVertex = .{
                    .position = position,
                    .normal = position * @as(@Vector(3, f32), @splat(lengthInv)),
                    .texCoords = .{
                        @as(f32, @floatFromInt(j)) / @as(f32, @floatFromInt(longitude)),
                        @as(f32, @floatFromInt(i)) / @as(f32, @floatFromInt(latitude)),
                    },
                };
                try vertices.append(vertex);
            }
            j = 0;
        }
    }

    var k1: u32 = 0;
    var k2: u32 = 0;
    var indices = std.ArrayList(u32).init(allocator);
    {
        var i: u32 = 0;
        var j: u32 = 0;
        while (i < latitude) : (i += 1) {
            k1 = i * (longitude + 1);
            k2 = k1 + longitude + 1;
            while (j < longitude) : (j += 1) {
                if (i != 0) {
                    try indices.appendSlice(&.{ k1, k2, k1 + 1 });
                }
                if (i != (latitude - 1)) {
                    try indices.appendSlice(&.{ k1 + 1, k2, k2 + 1 });
                }
                k1 += 1;
                k2 += 1;
            }
            j = 0;
        }
    }

    return .{
        .vertices = try vertices.toOwnedSlice(),
        .indices = try indices.toOwnedSlice(),
    };
}
