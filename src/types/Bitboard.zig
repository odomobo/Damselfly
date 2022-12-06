const std = @import("std");
const df = @import("../damselfly.zig");

const indexes = df.indexes;
const bitboards = df.bitboards;
const Offset = df.types.Offset;
const Index = df.types.Index;
const assert = std.debug.assert;

pub const Bitboard = struct {
    const Self = @This();

    pub const empty = Self{.val = 0};

    val: u64,    
};
