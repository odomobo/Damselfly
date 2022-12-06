const std = @import("std");
const df = @import("damselfly.zig");

const Score = df.types.Score;
const assert = std.debug.assert;

pub const maxScore: Score = 32000;
pub const minScore: Score = -32000;

const maxNonMatingScore: Score = 30000;

pub fn fromMating(distanceToMate: usize) Score {
    return @intCast(Score, maxScore - distanceToMate);
}

pub fn isMating(score: Score) bool {
    return std.math.absInt(score) > maxNonMatingScore;
}

pub fn getMatingDistance(score: Score) u16 {
    assert(isMating(score));
    return maxScore - std.math.absInt(score);
}