const std = @import("std");
const df = @import("../damselfly.zig");

const ZobristHash = df.types.ZobristHash;

pub fn init() void {
    zobristKeysInner = generateZobristKeys();
}

// Zobrist keys are ordered as follows:
// [0..63] First, all pawn keys, from bitboard index 0 through 63
// [64..127] Next, all knight keys, from bitboard index 0 through 63
// [128..383] Next all bishop, rook, queen, king keys, each from bitboard index 0 through 63
// [384..399] Next, all en passant squares, in order of a3 to h3, followed by a6 thorugh h6
// [400..404] Next, all castling keys: white kingside, white queenside, black kingside, black queenside in that order
// [405] Finally, the white-to-move key
pub var zobristKeysInner = [_]ZobristHash{0} ** zobristKeysSize;
// TODO: get rid of this once zig compiler issue is fixed
pub const zobristKeys = &zobristKeysInner;

const zobristKeysSize = 406;
fn generateZobristKeys() [zobristKeysSize]ZobristHash {
    var ret: [zobristKeysSize]ZobristHash = undefined;
    var rng = std.rand.DefaultPrng.init(0);
    
    var i: usize = 0;
    while(i < ret.len) : (i += 1) {
        ret[i] = rng.random().int(ZobristHash);
    }

    return ret;
}
