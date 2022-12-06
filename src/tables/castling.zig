const std = @import("std");
const df = @import("../damselfly.zig");

const Bitboard = df.types.Bitboard;
const bitboards = df.bitboards;

// piece masks

pub const whiteKingsidePieceMask = bitboards.fromStr(
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . O . . O   "
);

pub const whiteQueensidePieceMask = bitboards.fromStr(
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " O . . . O . . .   "
);

pub const blackKingsidePieceMask = bitboards.fromStr(
    " . . . . O . . O / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . .   "
);

pub const blackQueensidePieceMask = bitboards.fromStr(
    " O . . . O . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . .   "
);

// clear masks

pub const whiteKingsideClearMask = bitboards.fromStr(
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . O O .   "
);

pub const whiteQueensideClearMask = bitboards.fromStr(
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . O O O . . . .   "
);

pub const blackKingsideClearMask = bitboards.fromStr(
    " . . . . . O O . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . .   "
);

pub const blackQueensideClearMask = bitboards.fromStr(
    " . O O O . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . .   "
);

// passthrough squares

pub const whiteKingsidePassthroughSquare = bitboards.fromStr(
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . O . .   "
);

pub const whiteQueensidePassthroughSquare = bitboards.fromStr(
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . O . . . .   "
);

pub const blackKingsidePassthroughSquare = bitboards.fromStr(
    " . . . . . O . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . .   "
);

pub const blackQueensidePassthroughSquare = bitboards.fromStr(
    " . . . O . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . .   "
);