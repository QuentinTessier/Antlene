pub const Version = @This();

pub fn make(major: u8, minor: u8, patch: u16) u32 {
    return @shlExact(@as(u32, @intCast(major)), 24) | @shlExact(@as(u32, @intCast(minor)), 16) | patch;
}

pub fn getMajor(v: u32) u8 {
    const major = v & 0xFF000000;
    return @intCast(@shrExact(major, 24));
}

pub fn getMinor(v: u32) u8 {
    const minor = v & 0x00FF0000;
    return @intCast(@shrExact(minor, 16));
}

pub fn getPatch(v: u32) u16 {
    const patch = v & 0x0000FFFF;
    return @intCast(patch);
}
