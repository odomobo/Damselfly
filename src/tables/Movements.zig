const std = @import("std");
const df = @import("../damselfly.zig");

const assert = std.debug.assert;
const Offset = df.types.Offset;
const StaticArrayList = df.StaticArrayList;

pub const Movements = struct {
    pub fn byPieceType(pieceType: df.types.PieceType) []const Offset
    {
        assert(pieceType != df.types.PieceType.Pawn);
        assert(pieceType != df.types.PieceType.None);

        return MovementsTable[@enumToInt(pieceType)].getConstItems();
    }
};

const OffsetList = StaticArrayList(Offset, 8);
const o = Offset.fromStr;

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