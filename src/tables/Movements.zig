const std = @import("std");
const df = @import("../damselfly.zig");

const Offset = df.types.Offset;
const StaticArrayList = df.StaticArrayList;

pub const Movements = struct {
    pub fn byPiece(piece: df.types.Piece) []Offset
    {
        return MovementsTable[@enumToInt(piece)].getItems();
    }
}

const OffsetList = StaticArrayList(Offset, 8);
const o = Offset.fromStr;

const knightOffsets = OffsetList.fromSlice(&[_]Offset{
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

const bishopOffsets = OffsetList.fromSlice(&[_]Offset{
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

const rookOffsets = OffsetList.fromSlice(&[_]Offset{
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

const queenOffsets = OffsetList.fromSlice(bishopOffsets ++ rookOffsets);
const kingOffsets = queenOffsets;

const MovementsTable = [_]OffsetList{
    OffsetList{}, // Pawn (unused)
    knightOffsets,
    bishopOffsets,
    rookOffsets,
    queenOffsets,
    kingOffsets,
};