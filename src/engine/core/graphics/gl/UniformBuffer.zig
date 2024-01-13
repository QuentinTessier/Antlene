const std = @import("std");
const gl = @import("gl");

pub fn UniformBuffer(comptime T: type, comptime binding: u32) type {
    if (@typeInfo(T) != .Struct) @panic("UniformBuffer(T): T should be a struct");
    const fields = std.meta.fields(T);
    for (fields) |f| {
        if (f.type == bool) @panic("UniformBuffer(T): GPU represent bool has int");
    }
    return struct {
        handle: u32,

        pub fn init() @This() {
            var self: @This() = undefined;
            gl.genBuffers(1, @ptrCast(&self.handle));
            gl.bindBuffer(gl.UNIFORM_BUFFER, self.handle);
            gl.bufferData(gl.UNIFORM_BUFFER, @sizeOf(T), null, gl.STATIC_DRAW);
            gl.bindBuffer(gl.UNIFORM_BUFFER, 0);

            gl.bindBufferBase(gl.UNIFORM_BUFFER, binding, self.handle);
            return self;
        }

        pub fn deinit(self: @This()) void {
            gl.deleteBuffers(1, @ptrCast(&self.handle));
        }

        pub fn update(self: @This(), data: T) void {
            gl.bindBuffer(gl.UNIFORM_BUFFER, self.handle);
            gl.bufferData(gl.UNIFORM_BUFFER, @sizeOf(T), &data, gl.STATIC_DRAW);
            gl.bindBuffer(gl.UNIFORM_BUFFER, 0);
        }

        pub fn updateMember(self: @This(), comptime field: std.meta.FieldEnum(T), data: std.meta.FieldType(T, field)) void {
            gl.bindBuffer(gl.UNIFORM_BUFFER, self.handle);
            gl.bufferSubData(gl.UNIFORM_BUFFER, @offsetOf(T, @tagName(field)), @sizeOf(@TypeOf(data)), &data);
            gl.bindBuffer(gl.UNIFORM_BUFFER, 0);
        }
    };
}
