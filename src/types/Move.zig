const std = @import("std");
const df = @import("../damselfly.zig");

const Piece = df.types.Piece;
const PieceType = df.types.PieceType;
const Color = df.types.Color;
const Index = df.types.Index;
const indexes = df.indexes;

pub const Move = struct {
    const Self = @This();

    pub const MoveType = enum {
        Normal,
        Promotion,
        DoubleMove,
        EnPassant,
        Castling,
    };

    pieceType: PieceType,
    moveType: MoveType,
    capture: bool,
    srcIndex: Index,
    dstIndex: Index,
    promotionPieceType: PieceType = PieceType.None,

    // TODO: add a long format that includes captures, and shows castling differently... maybe???
    pub fn format(self: Self, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void
    {
        if (self.moveType == .Promotion) {
            // note: we print black piece because they are naturally lowercase
            try writer.print("{}{}{short}", .{indexes.indexToFormattable(self.srcIndex), indexes.indexToFormattable(self.dstIndex), Piece.init(Color.Black, self.promotionPieceType)});
        } else {
            try writer.print("{}{}", .{indexes.indexToFormattable(self.srcIndex), indexes.indexToFormattable(self.dstIndex)});
        }
    }
};