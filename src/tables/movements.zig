const std = @import("std");
const df = @import("../damselfly.zig");

const assert = std.debug.assert;
const assertDebug = df.debug.assertDebug;
const assertParanoid = df.debug.assertParanoid;

const Offset = df.types.Offset;
const StaticArrayList = df.StaticArrayList;
const PieceType = df.types.PieceType;
const Color = df.types.Color;
const Bitboard = df.types.Bitboard;
const indexes = df.indexes;
const bitboards = df.bitboards;

pub fn byPieceType(comptime pieceType: PieceType) []const Offset
{
    assert(pieceType != PieceType.Pawn);
    assert(pieceType != PieceType.None);

    return MovementsTable[@enumToInt(pieceType)];
}

pub fn pawnNormalMove(sideToMove: Color) Offset {
    return switch (sideToMove) {
        Color.White => Offset.fromStr(
            " 2 / " ++
            " 1 "
        ),
        Color.Black => Offset.fromStr(
            " 1 / " ++
            " 2   "
        ),
    };
}

pub fn pawnDoubleMove(sideToMove: Color) Offset {
    return switch (sideToMove) {
        Color.White => Offset.fromStr(
            " 2 / " ++
            " . / " ++
            " 1   "
        ),
        Color.Black => Offset.fromStr(
            " 1 / " ++
            " . / " ++
            " 2   "
        ),
    };
}

pub fn pawnIsDoubleMoveAllowed(sideToMove: Color, square: Bitboard) bool {
    assertDebug(bitboards.popCount(square) == 1);

    const allowedBb = switch (sideToMove) {
        Color.White => bitboards.fromStr(
            " . . . . . . . . / " ++
            " . . . . . . . . / " ++
            " . . . . . . . . / " ++
            " . . . . . . . . / " ++
            " . . . . . . . . / " ++
            " . . . . . . . . / " ++
            " O O O O O O O O / " ++
            " . . . . . . . .   "
        ),
        Color.Black => bitboards.fromStr(
            " . . . . . . . . / " ++
            " O O O O O O O O / " ++
            " . . . . . . . . / " ++
            " . . . . . . . . / " ++
            " . . . . . . . . / " ++
            " . . . . . . . . / " ++
            " . . . . . . . . / " ++
            " . . . . . . . .   "
        ),
    };
    return square & allowedBb != 0;
}

pub fn pawnIsFinalRank(sideToMove: Color, square: Bitboard) bool {
    assertDebug(bitboards.popCount(square) == 1);

    const allowedBb = switch (sideToMove) {
        Color.White => bitboards.fromStr(
            " . . . . . . . . / " ++
            " O O O O O O O O / " ++
            " . . . . . . . . / " ++
            " . . . . . . . . / " ++
            " . . . . . . . . / " ++
            " . . . . . . . . / " ++
            " . . . . . . . . / " ++
            " . . . . . . . .   "
        ),
        Color.Black => bitboards.fromStr(
            " . . . . . . . . / " ++
            " . . . . . . . . / " ++
            " . . . . . . . . / " ++
            " . . . . . . . . / " ++
            " . . . . . . . . / " ++
            " . . . . . . . . / " ++
            " O O O O O O O O / " ++
            " . . . . . . . .   "
        ),
    };
    return square & allowedBb != 0;
}

pub fn pawnCaptures(sideToMove: Color) []const Offset {
    return switch (sideToMove) {
        Color.White => &whitePawnAttackOffsets,
        Color.Black => &blackPawnAttackOffsets,
    };
}


const o = Offset.fromStr;

pub const whitePawnAttackOffsets = [_]Offset{
    o(
        " . 2 / " ++
        " 1 .   "
    ),
    o(
        " 2 . / " ++
        " . 1   "
    ),
};

pub const blackPawnAttackOffsets = [_]Offset{
    o(
        " 1 . / " ++
        " . 2   "
    ),
    o(
        " . 1 / " ++
        " 2 .   "
    ),
};

pub const knightOffsets = [_]Offset{
    o(
        " . 2 / " ++
        " . . / " ++
        " 1 .   "
    ),
    o(
        " . . 2 / " ++
        " 1 . .   "
    ),
    o(
        " 1 . . / " ++
        " . . 2   "
    ),
    o(
        " 1 . / " ++
        " . . / " ++
        " . 2   "
    ),
    o(
        " . 1 / " ++
        " . . / " ++
        " 2 .   "
    ),
    o(
        " . . 1 / " ++
        " 2 . .   "
    ),
    o(
        " 2 . . / " ++
        " . . 1   "
    ),
    o(
        " 2 . / " ++
        " . . / " ++
        " . 1   "
    ),
};

pub const bishopOffsets = [_]Offset{
    o(
        " . 2 / " ++
        " 1 .   "
    ),
    o(
        " 1 . / " ++
        " . 2   "
    ),
    o(
        " . 1 / " ++
        " 2 .   "
    ),
    o(
        " 2 . / " ++
        " . 1   "
    ),
};

pub const rookOffsets = [_]Offset{
    o(
        " 2 / " ++
        " 1   "
    ),
    o(
        " 1 2 "
    ),
    o(
        " 1 / " ++
        " 2   "
    ),
    o(
        " 2 1 "
    ),
};

pub const queenOffsets = bishopOffsets ++ rookOffsets;
pub const kingOffsets = queenOffsets;

const MovementsTable = [_][]const Offset{
    &[_]Offset{}, // Pawn (unused)
    &knightOffsets,
    &bishopOffsets,
    &rookOffsets,
    &queenOffsets,
    &kingOffsets,
};