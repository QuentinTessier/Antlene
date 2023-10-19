const std = @import("std");
const gl = @import("../Platform/gl/gl.zig");

pub const VertexArray = @This();

pub const Type = enum(u32) {
    Byte = gl.BYTE,
    UnsignedByte = gl.UNSIGNED_BYTE,
    Short = gl.SHORT,
    UnsignedShort = gl.UNSIGNED_SHORT,
    Int = gl.INT,
    UnsignedInt = gl.UNSIGNED_INT,
    Float = gl.FLOAT,
    HalfFloat = gl.HALF_FLOAT,
    Double = gl.DOUBLE,
    Fixed = gl.FIXED,

    pub fn fromType(comptime T: type) Type {
        switch (@typeInfo(T)) {
            .Int => |int| {
                switch (int.bits) {
                    8 => return if (int.signedness == .signed) Type.Byte else Type.UnsignedByte,
                    16 => return if (int.signedness == .signed) Type.Short else Type.UnsignedShort,
                    32 => return if (int.signedness == .signed) Type.Int else Type.UnsignedInt,
                    else => unreachable,
                }
            },
            .Float => |float| {
                switch (float.bits) {
                    16 => return Type.HalfFloat,
                    32 => return Type.Float,
                    64 => return Type.Double,
                    else => unreachable,
                }
            },
            else => unreachable,
        }
    }

    pub fn toGL(self: Type) u32 {
        return @intFromEnum(self);
    }
};

pub const Attrib = struct {
    type: Type,
    count: usize,
    size: usize,
    normalize: bool = false,
};

pub const Layout = struct {
    stride: usize,
    attribs: []const Attrib,
};

handle: u32,

pub fn create() VertexArray {
    var handle: u32 = 0;
    gl.genVertexArrays(1, &handle);

    return .{
        .handle = handle,
    };
}

pub fn destroy(self: *VertexArray) void {
    gl.deleteVertexArrays(1, &self.handle);
}

fn attribFromType(comptime T: type, normalize: bool) Attrib {
    switch (@typeInfo(T)) {
        .Int => |int| {
            _ = int;
            return Attrib{
                .count = 1,
                .normalize = normalize,
                .size = @sizeOf(T),
                .type = Type.fromType(T),
            };
        },
        .Float => |float| {
            _ = float;
            return Attrib{
                .count = 1,
                .normalize = normalize,
                .size = @sizeOf(T),
                .type = Type.fromType(T),
            };
        },
        .Vector => |vector| {
            return Attrib{
                .count = @as(usize, vector.len),
                .normalize = normalize,
                .size = @sizeOf(T) * vector.len,
                .type = Type.fromType(vector.child),
            };
        },
        .Array => |array| {
            return Attrib{
                .count = @as(usize, array.len),
                .normalize = normalize,
                .size = @sizeOf(array.child) * array.len,
                .type = Type.fromType(array.child),
            };
        },
        else => unreachable,
    }
}

pub fn layoutFromType(comptime T: type) Layout {
    if (@typeInfo(T) != .Struct) {
        @compileError("layoutFromType takes a structure has argument");
    }
    const fields = std.meta.fields(T);
    if (fields.len == 0) {
        @compileError("layoutFromType takes a not empty structure has argument");
    }
    var attribs: [64]Attrib = undefined;
    for (fields, 0..) |field, i| {
        attribs[i] = attribFromType(field.type, false);
    }

    return Layout{
        .stride = @sizeOf(T),
        .attribs = attribs[0..fields.len],
    };
}

pub fn setAttribPointers(self: *VertexArray, layout: Layout) void {
    _ = self;
    var offset: usize = 0;
    for (layout.attribs, 0..) |attrib, i| {
        const vIndex: u32 = @intCast(i);
        const count: i32 = @intCast(attrib.count);
        const glType = attrib.type.toGL();
        const stride: i32 = @intCast(layout.stride);
        const normalize = @as(u8, if (attrib.normalize) gl.TRUE else gl.FALSE);

        gl.enableVertexAttribArray(vIndex);
        gl.vertexAttribPointer(vIndex, count, glType, normalize, stride, @as(?*anyopaque, @ptrFromInt(offset)));
        offset += attrib.size;
    }
}

pub fn bind(self: *VertexArray) void {
    gl.bindVertexArray(self.handle);
}

pub fn unbind(self: *VertexArray) void {
    _ = self;
    gl.bindVertexArray(0);
}
