const std = @import("std");
const rl = @import("raylib");

pub const SpriteAnimator = @This();

atlasName: []const u8,
regions: []const usize,
currentRegion: usize = 0,
elapsed: f32 = 0.0,
framerate: f32 = 16.0,
