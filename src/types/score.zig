const std = @import("std");
const df = @import("../damselfly.zig");

pub const Score = packed struct(u16) {
    const Self = @This();
    pub const Type = enum(u1) {
        Mate,
        Normal,
    };

    type: Type,
    val: i15,

    pub fn initMating(gamePly: usize) Self {
        return Self {
            .type = Type.Mate,
            .val = std.math.maxInt(i15) - @intCast(i15, gamePly),
        };
    }

    pub fn initMated(gamePly: usize) Self {
        return initMating(gamePly).negate();
    }

    pub fn initScore(score: isize) Self {
        return Self {
            .type = Type.Normal,
            .val = @intCast(i15, score),
        };
    }

    pub fn negate(self: Self) Self {
        return Self {
            .type = self.type,
            .val = -self.val,
        };
    }

    // TODO: access mating information, access mating depth, etc.
};
