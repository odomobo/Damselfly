const std = @import("std");
const df = @import("../damselfly.zig");

const Piece = df.types.Piece;
const PieceType = df.types.PieceType;
const Color = df.types.Color;
const bits = df.bits;

pub const Move = struct {
    const Self = @This();

    pub const MoveType = packed struct(u8) {
        normal: bool = false,
        doubleMove: bool = false,
        enPassant: bool = false,
        promotion: bool = false,
        castling: bool = false,
        quiet: bool = false,
        capture: bool = false,
        _: u1 = 0,
    };

    moveType: MoveType,
    srcIndex: i8,
    dstIndex: i8,
    promotionPieceType: PieceType = PieceType.None,

    // TODO: add a long format that includes captures, and shows castling differently... maybe???
    pub fn format(self: Self, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void
    {
        if (self.moveType.promotion) {
            // note: we print black piece because they are naturally lowercase
            try writer.print("{}{}{short}", .{bits.indexToFormattable(self.srcIndex), bits.indexToFormattable(self.dstIndex), Piece.init(Color.Black, self.promotionPieceType)});
        } else {
            try writer.print("{}{}", .{bits.indexToFormattable(self.srcIndex), bits.indexToFormattable(self.dstIndex)});
        }
    }
};