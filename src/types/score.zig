const std = @import("std");
const df = @import("../damselfly.zig");

pub const Score = packed struct(u16) {
    const Self = @This();
    pub const ScoreType = enum(u1) {
        Mate,
        Normal,
    };

    scoreType: ScoreType,
    val: i15,

    pub fn initMating(gamePly: usize) Self {
        return Self {
            .scoreType = ScoreType.Mate,
            .val = std.math.maxInt(i15) - @intCast(i15, gamePly),
        };
    }

    pub fn initMated(gamePly: usize) Self {
        return initMating(gamePly).negate();
    }

    pub fn initScore(score: isize) Self {
        return Self {
            .scoreType = ScoreType.Normal,
            .val = @intCast(i15, score),
        };
    }

    pub fn negate(self: Self) Self {
        return Self {
            .scoreType = self.ScoreType,
            .val = -self.val,
        };
    }

    // TODO: access mating information, access mating depth, etc.
};
