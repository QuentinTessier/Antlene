const std = @import("std");
const gl = @import("../Platform/gl/gl.zig");

pub const Target = enum(u32) {
    Array = gl.ARRAY_BUFFER,
    AtomicCounter = gl.ATOMIC_COUNTER_BUFFER,
    CopyRead = gl.COPY_READ_BUFFER,
    CopyWrite = gl.COPY_WRITE_BUFFER,
    DispatchIndirect = gl.DISPATCH_INDIRECT_BUFFER,
    DrawIndirect = gl.DRAW_INDIRECT_BUFFER,
    Element = gl.ELEMENT_ARRAY_BUFFER,
    PixelPack = gl.PIXEL_PACK_BUFFER,
    PixelUnpack = gl.PIXEL_UNPACK_BUFFER,
    Query = gl.QUERY_BUFFER,
    ShaderStorage = gl.SHADER_STORAGE_BUFFER,
    Texture = gl.TEXTURE_BUFFER,
    TransformFeedback = gl.TRANSFORM_FEEDBACK_BUFFER,
    Uniform = gl.UNIFORM_BUFFER,

    pub inline fn toGL(self: Target) u32 {
        return @intFromEnum(self);
    }
};

pub const Usage = enum(u32) {
    StreamDraw = gl.STREAM_DRAW,
    StreamRead = gl.STREAM_READ,
    StreamCopy = gl.STREAM_COPY,
    StaticDraw = gl.STATIC_DRAW,
    StaticRead = gl.STATIC_READ,
    StaticCopy = gl.STATIC_COPY,
    DymanicDraw = gl.DYNAMIC_DRAW,
    DymanicRead = gl.DYNAMIC_READ,
    DymanicCopy = gl.DYNAMIC_COPY,

    pub inline fn toGL(self: Usage) u32 {
        return @intFromEnum(self);
    }
};

pub const Parameters = enum(u32) {
    BufferAccess = gl.BUFFER_ACCESS,
    BufferMapped = gl.BUFFER_MAPPED,
    BufferSize = gl.BUFFER_SIZE,
    BufferUsage = gl.BUFFER_USAGE,

    pub inline fn toGL(self: Parameters) u32 {
        return @intFromEnum(self);
    }
};

pub const Buffer = @This();

handle: u32,
size: usize,
target: Target,
usage: Usage,

pub fn createEmpty(target: Target, usage: Usage, size: usize) Buffer {
    std.log.info("Creating a buffer:{} with a size of {}", .{ target, size });
    var handle: u32 = 0;
    gl.genBuffers(1, &handle);
    gl.bindBuffer(target.toGL(), handle);
    gl.bufferData(target.toGL(), @as(c_longlong, @intCast(size)), null, usage.toGL());

    return Buffer{
        .handle = handle,
        .size = size,
        .target = target,
        .usage = usage,
    };
}

pub fn create(comptime T: type, data: []T, target: Target, usage: Usage) Buffer {
    const size: usize = @sizeOf(T) * data.len;

    var handle: u32 = 0;
    gl.genBuffers(1, &handle);
    gl.bindBuffer(target.toGL(), handle);
    gl.bufferData(target.toGL(), @as(c_longlong, @intCast(size)), data.ptr, usage.toGL());

    return Buffer{
        .handle = handle,
        .size = size,
        .target = target,
        .usage = usage,
    };
}

pub inline fn destroy(self: *Buffer) void {
    gl.deleteBuffers(1, &self.handle);
    self.handle = 0;
}

pub inline fn getParameter(self: *const Buffer, parameter: Parameters) i32 {
    var value: i32 = 0;
    gl.bindBuffer(self.target.toGL(), self.handle);
    gl.getBufferParameteriv(self.target.toGL(), parameter.toGL(), &value);
    gl.bindBuffer(self.target.toGL(), 0);
    return value;
}

pub fn updateData(self: *Buffer, comptime T: type, data: []T, offset: usize) void {
    const size: usize = @sizeOf(T) * data.len;
    if (offset + size > self.size) return;

    gl.bindBuffer(self.target.toGL(), self.handle);
    gl.bufferSubData(self.target.toGL(), @intCast(offset), @intCast(size), data.ptr);
    gl.bindBuffer(self.target.toGL(), 0);
}

pub fn bind(self: *Buffer) void {
    gl.bindBuffer(self.target.toGL(), self.handle);
}

pub fn unbind(self: *Buffer) void {
    gl.bindBuffer(self.target.toGL(), 0);
}
