const std = @import("std");
const df = @import("../damselfly.zig");

const assert = std.debug.assert;
const Offset = df.types.Offset;
const StaticArrayList = df.StaticArrayList;
const PieceType = df.types.PieceType;
const Color = df.types.Color;
const Bitboard = df.types.Bitboard;
const bits = df.bits;

pub const Movements = struct {
    pub fn byPieceType(comptime pieceType: PieceType) []const Offset
    {
        assert(pieceType != PieceType.Pawn);
        assert(pieceType != PieceType.None);

        return MovementsTable[@enumToInt(pieceType)].getConstItems();
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

    pub fn pawnDoubleMoveAllowed(sideToMove: Color, piece: Bitboard) bool {
        assert(bits.popCount(piece.val) == 1); // TODO: assertParanoid

        const allowedBb = switch (sideToMove) {
            Color.White => Bitboard.fromStr(
                " . . . . . . . . / " ++
                " . . . . . . . . / " ++
                " . . . . . . . . / " ++
                " . . . . . . . . / " ++
                " . . . . . . . . / " ++
                " . . . . . . . . / " ++
                " O O O O O O O O / " ++
                " . . . . . . . .   "
            ),
            Color.Black => Bitboard.fromStr(
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
        return (piece.val & allowedBb.val) != 0;
    }

    pub fn pawnIsFinalRank(sideToMove: Color, piece: Bitboard) bool {
        assert(bits.popCount(piece.val) == 1); // TODO: assertParanoid

        const allowedBb = switch (sideToMove) {
            Color.White => Bitboard.fromStr(
                " . . . . . . . . / " ++
                " O O O O O O O O / " ++
                " . . . . . . . . / " ++
                " . . . . . . . . / " ++
                " . . . . . . . . / " ++
                " . . . . . . . . / " ++
                " . . . . . . . . / " ++
                " . . . . . . . .   "
            ),
            Color.Black => Bitboard.fromStr(
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
        return (piece.val & allowedBb.val) != 0;
    }

    pub fn pawnCaptures(sideToMove: Color) []const Offset {
        return switch (sideToMove) {
            Color.White => whitePawnAttackOffsets.getConstItems(),
            Color.Black => blackPawnAttackOffsets.getConstItems(),
        };
    }
};

const OffsetList = StaticArrayList(Offset, 8);
const o = Offset.fromStr;

pub const whitePawnAttackOffsets = OffsetList.fromSlice(&[_]Offset{
    o(
        " . 2 / " ++
        " 1 .   "
    ),
    o(
        " 2 . / " ++
        " . 1   "
    ),
});

pub const blackPawnAttackOffsets = OffsetList.fromSlice(&[_]Offset{
    o(
        " 1 . / " ++
        " . 2   "
    ),
    o(
        " . 1 / " ++
        " 2 .   "
    ),
});

pub const knightOffsets = OffsetList.fromSlice(&[_]Offset{
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
});

pub const bishopOffsets = OffsetList.fromSlice(&[_]Offset{
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
});

pub const rookOffsets = OffsetList.fromSlice(&[_]Offset{
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
});

// TODO: get the below to work somehow
//pub const queenOffsets = OffsetList.fromSlice(bishopOffsets.getConstItems() ++ rookOffsets.getConstItems());
pub const queenOffsets = OffsetList.fromSlice(&[_]Offset{
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
});
pub const kingOffsets = queenOffsets;

const MovementsTable = [_]OffsetList{
    OffsetList{}, // Pawn (unused)
    knightOffsets,
    bishopOffsets,
    rookOffsets,
    queenOffsets,
    kingOffsets,
};