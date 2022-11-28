const std = @import("std");
const df = @import("../damselfly.zig");

const Piece = df.types.Piece;

pub const Move = packed struct {
    const Self = @This();

    pub const MoveType = packed struct(u8) {
        normal: bool,
        doubleMove: bool,
        enPassant: bool,
        promotion: bool,
        castling: bool,
        quiet: bool,
        capture: bool,
        _: u1,
    };

    moveType: MoveType,
    srcIndex: i8,
    dstIndex: i8,
    promotionPiece: Piece,
};