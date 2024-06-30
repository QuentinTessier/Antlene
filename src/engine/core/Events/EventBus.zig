const std = @import("std");
const WindowEvent = @import("AntleneWindowSystem").Events;

const ZigUtils = @import("../../zig/utils.zig");

pub fn Bus(comptime T: type) type {
    return struct {
        const CallbackType = *const fn (*anyopaque, T) void;
        const Listener = struct {
            self: *anyopaque,
            callback: CallbackType,
        };

        listeners: std.ArrayListUnmanaged(Listener) = .{},
        postponed: std.fifo.LinearFifo(T, .{ .Static = 64 }),

        pub fn deinit(self: *@This(), allocator: std.mem.Allocator) void {
            self.listeners.deinit(allocator);
            self.postponed.deinit();
        }

        pub fn listen(self: *@This(), allocator: std.mem.Allocator, obj: anytype, callback: anytype) !void {
            try self.listeners.append(allocator, .{
                .self = obj,
                .callback = @ptrCast(callback),
            });
        }

        pub fn notify(self: *const @This(), event: T) void {
            for (self.listeners.items) |listener| {
                listener.callback(listener.self, event);
            }
        }

        pub fn postpone(self: *@This(), event: T) !void {
            try self.postponed.writeItem(event);
        }

        pub fn process(self: *@This()) void {
            while (self.postponed.readItem()) |event| {
                self.notify(event);
            }
        }
    };
}

fn GenerateEventBusPayloadType(comptime EventTypes: []const type) type {
    var fields: []const std.builtin.Type.StructField = &[0]std.builtin.Type.StructField{};
    for (EventTypes) |T| {
        fields = fields ++ [1]std.builtin.Type.StructField{.{
            .type = Bus(T),
            .name = ZigUtils.GetDemangledTypeName(T),
            .is_comptime = false,
            .default_value = null,
            .alignment = @alignOf(Bus(T)),
        }};
    }
    return @Type(.{ .Struct = .{
        .fields = fields,
        .is_tuple = false,
        .layout = .auto,
        .decls = &[_]std.builtin.Type.Declaration{},
    } });
}

pub fn EventBus(comptime EventTypes: []const type) type {
    return struct {
        const PayloadType: type = GenerateEventBusPayloadType(EventTypes);

        allocator: std.mem.Allocator,
        payload: PayloadType,

        pub fn init(allocator: std.mem.Allocator) @This() {
            var bus = @This(){
                .allocator = allocator,
                .payload = undefined,
            };
            const fields = std.meta.fields(PayloadType);
            inline for (fields) |f| {
                @field(bus.payload, f.name).listeners = .{};
                @field(bus.payload, f.name).postponed = @TypeOf(@field(bus.payload, f.name).postponed).init();
            }
            return bus;
        }

        pub fn deinit(self: *@This()) void {
            const fields = std.meta.fields(PayloadType);
            inline for (fields) |f| {
                @field(self.payload, f.name).deinit(self.allocator);
            }
        }

        pub fn listen(self: *@This(), comptime T: type, obj: anytype, callback: anytype) !void {
            const field_name = comptime ZigUtils.GetDemangledTypeName(T);

            try @field(self.payload, field_name).listen(self.allocator, obj, callback);
        }

        // Instantly run the callbacks
        pub fn notify(self: *const @This(), event: anytype) void {
            const field_name = comptime ZigUtils.GetDemangledTypeName(@TypeOf(event));
            if (!@hasField(PayloadType, field_name)) @panic("EventBus doesn't have a event with type name " ++ field_name);

            @field(self.payload, field_name).notify(event);
        }

        pub fn postpone(self: *@This(), event: anytype) void {
            const field_name = comptime ZigUtils.GetDemangledTypeName(@TypeOf(event));
            if (!@hasField(PayloadType, field_name)) @panic("EventBus doesn't have a event with type name " ++ field_name);

            try @field(self.payload, field_name).postpone(self.allocator, event);
        }

        pub fn process(self: *@This()) void {
            const fields = std.meta.fields(PayloadType);
            inline for (fields) |f| {
                @field(self.payload, f.name).process();
            }
        }
    };
}
