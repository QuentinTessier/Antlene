const std = @import("std");
const antlene = @import("antlene");
const game = @import("game");

pub fn main() anyerror!void {
    try antlene.entry(game.getApplicationInformation());
}
