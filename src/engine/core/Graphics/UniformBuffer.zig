const std = @import("std");
const gl = @import("../Platform/gl/gl.zig");

pub fn TypedUniformBuffer(comptime T: type) type {
    if (@typeInfo(T) != .Struct) @compileError("Provide a structure");

    return struct {
        const Self = @This();

        handle: u32,

        pub const Fields = std.meta.fields(T);
        pub const FieldEnum = std.meta.FieldEnum(T);

        pub fn init(default_value: ?T) Self {
            var handle: u32 = 0;
            gl.genBuffers(1, &handle);
            gl.bindBuffer(gl.UNIFORM_BUFFER, handle);
            if (default_value) |default| {
                gl.bufferData(gl.UNIFORM_BUFFER, @sizeOf(T), &default, gl.STATIC_DRAW);
            } else {
                gl.bufferData(gl.UNIFORM_BUFFER, @sizeOf(T), null, gl.STATIC_DRAW);
            }
            gl.bindBuffer(gl.UNIFORM_BUFFER, 0);
            return .{ .handle = handle };
        }

        pub fn deinit(self: *Self) void {
            gl.deleteBuffers(1, &self.handle);
        }

        pub fn update(self: *Self, value: T) void {
            gl.bindBuffer(gl.UNIFORM_BUFFER, self.handle);

            gl.bufferSubData(gl.UNIFORM_BUFFER, 0, @intCast(@sizeOf(T)), &value);

            gl.bindBuffer(gl.UNIFORM_BUFFER, 0);
        }

        pub fn updateMember(self: *Self, comptime field: FieldEnum, value: anytype) void {
            const fieldType = Fields[@intFromEnum(field)].type;
            const fieldName = Fields[@intFromEnum(field)].name;
            const fieldSize = @sizeOf(fieldType);
            if (@TypeOf(value) != fieldType) @compileError("Field Type doesn't match value given");

            gl.bindBuffer(gl.UNIFORM_BUFFER, self.handle);

            const offset = @offsetOf(T, fieldName);

            gl.bufferSubData(gl.UNIFORM_BUFFER, @intCast(offset), @intCast(fieldSize), &value);

            gl.bindBuffer(gl.UNIFORM_BUFFER, 0);
        }
    };
}
