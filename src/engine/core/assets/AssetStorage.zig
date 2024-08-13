const std = @import("std");
const utils = @import("../../zig/utils.zig");

const AssetFactory = @import("AssetFactory.zig");

pub const AssetStorage = @This();

allocator: std.mem.Allocator,
factories: std.StringHashMap(*AssetFactory.AssetFactory),

pub fn init(allocator: std.mem.Allocator) AssetStorage {
    return .{
        .allocator = allocator,
        .factories = std.StringHashMap(*AssetFactory.AssetFactory).init(allocator),
    };
}

pub fn deinit(self: *AssetStorage) void {
    var ite = self.factories.iterator();
    while (ite.next()) |entry| {
        entry.value_ptr.*.deinit(entry.value_ptr.*);
    }
    self.factories.deinit();
}

pub fn newAssetType(self: *AssetStorage, comptime AssetDescription: type) !*AssetFactory.TypedAssetFactory(AssetDescription.AssetType, AssetDescription.load, AssetDescription.unload) {
    const FactoryType = AssetFactory.TypedAssetFactory(AssetDescription.AssetType);
    const name = FactoryType.getName();

    const factory = try self.allocator.create(FactoryType);
    factory.* = try FactoryType.init(self.allocator);
    self.factories.put(name, &factory.base);

    return factory;
}

pub fn getFactoryByType(self: *AssetStorage, comptime AssetType: type) ?*AssetFactory.TypedAssetFactory(AssetType) {
    const name = AssetFactory.TypedAssetFactory(AssetType).getName();
    const possibleFactory = self.factories.get(name);
    return if (possibleFactory) |factory| factory.toTypedAssetFactory(AssetType) else null;
}

pub fn newAsset(self: *AssetStorage, comptime AssetType: type, ressourceAllocator: std.mem.Allocator, args: anytype) !AssetFactory.TypedAssetFactory(AssetType).Handle {
    const factory = self.getFactoryByType(AssetType) orelse return error.NoSuchFactory;

    return factory.new(ressourceAllocator, args);
}

pub fn getAsset(self: *AssetStorage, comptime AssetType: type, handle: AssetFactory.TypedAssetFactory(AssetType).Handle) ?AssetType {
    const factory = self.getFactoryByType(AssetType) orelse return error.NoSuchFactory;

    return factory.get(handle);
}
