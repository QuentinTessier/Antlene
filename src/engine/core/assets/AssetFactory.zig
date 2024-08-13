const std = @import("std");
const utils = @import("../../zig/utils.zig");
const Pool = @import("zpool").Pool;

const Memory = @import("../Memory.zig");

pub const AssetFactory = struct {
    mutex: std.Thread.Mutex = .{},
    deinit: *const fn (*AssetFactory) void,

    pub fn toTypedAssetFactory(self: *AssetFactory, comptime AssetType: type) *TypedAssetFactory(AssetType) {
        return @fieldParentPtr("base", self);
    }
};

pub fn TypedAssetFactory(comptime T: type) type {
    return struct {
        const Self = @This();

        pub fn getName() [:0]const u8 {
            return utils.GetDemangledTypeName(T);
        }

        const P = Pool(16, 16, T, struct {
            asset: T,
            refCount: std.atomic.Value(usize),
        });
        base: AssetFactory,
        pool: P,

        pub const Handle = P.Handle;

        pub fn init(allocator: std.mem.Allocator) !@This() {
            return .{
                .base = .{},
                .pool = try P.initMaxCapacity(allocator),
            };
        }

        pub fn deinit(self: *@This()) void {
            self.pool.deinit();
        }

        pub fn lock(self: *@This()) void {
            self.base.mutex.lock();
        }

        pub fn unlock(self: *@This()) void {
            self.base.mutex.unlock();
        }

        pub fn new(self: *@This(), allocator: std.mem.Allocator, args: anytype) !Handle {
            self.lock();
            defer self.unlock();

            return self.pool.add(.{
                .asset = try @call(.auto, T.load, .{allocator} ++ args),
                .refCount = std.atomic.Value(usize).init(0),
            });
        }

        pub fn get(self: *@This(), handle: Handle) ?T {
            const possible_asset = self.pool.getColumnIfLive(handle, .asset);
            if (possible_asset) |asset| {
                const refCount = self.pool.getColumnPtrAssumeLive(handle, .refCount);
                _ = @atomicRmw(usize, refCount, .Add, 1, .acq_rel);
                return asset;
            }
            return null;
        }

        pub fn getPtr(self: *@This(), handle: Handle) ?*T {
            const possible_asset = self.pool.getColumnPtrIfLive(handle, .asset);
            if (possible_asset) |asset| {
                const refCount = self.pool.getColumnPtrAssumeLive(handle, .refCount);
                _ = @atomicRmw(usize, refCount, .Add, 1, .acq_rel);
                return asset;
            }
            return null;
        }

        pub fn release(self: *@This(), handle: Handle) !void {
            self.lock();
            defer self.unlock();

            const possibleRefCount = self.pool.getColumnPtrIfLive(handle, .refCount);
            if (possibleRefCount) |refCount| {
                if (@atomicRmw(usize, refCount, .Sub, 1, .acq_rel) == 0) {
                    const asset = self.pool.getColumnPtrUnchecked(handle, .asset);
                    @call(.auto, T.unload, .{ Memory.Allocator, asset });
                    try self.pool.remove(handle);
                }
            } else {
                std.log.warn("Resource with handle {} has already been released", .{handle});
            }
        }
    };
}
