const std = @import("std");
const df = @import("../damselfly.zig");

const Bitboard = df.types.Bitboard;

// piece masks

pub const whiteKingsidePieceMask = Bitboard.fromStr(
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . O . . O   "
);

pub const whiteQueensidePieceMask = Bitboard.fromStr(
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " O . . . O . . .   "
);

pub const blackKingsidePieceMask = Bitboard.fromStr(
    " . . . . O . . O / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . .   "
);

pub const blackQueensidePieceMask = Bitboard.fromStr(
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

pub const whiteKingsideClearMask = Bitboard.fromStr(
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . O O .   "
);

pub const whiteQueensideClearMask = Bitboard.fromStr(
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . O O O . . . .   "
);

pub const blackKingsideClearMask = Bitboard.fromStr(
    " . . . . . O O . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . .   "
);

pub const blackQueensideClearMask = Bitboard.fromStr(
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

pub const whiteKingsidePassthroughSquare = Bitboard.fromStr(
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . O . .   "
);

pub const whiteQueensidePassthroughSquare = Bitboard.fromStr(
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . O . . . .   "
);

pub const blackKingsidePassthroughSquare = Bitboard.fromStr(
    " . . . . . O . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . .   "
);

pub const blackQueensidePassthroughSquare = Bitboard.fromStr(
    " . . . O . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . . / " ++
    " . . . . . . . .   "
);