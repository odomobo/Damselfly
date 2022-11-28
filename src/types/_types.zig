
pub const Color = @import("Color.zig").Color;
pub const PieceType = @import("PieceType.zig").PieceType;
pub const Piece = @import("Piece.zig"); // TODO: just use normal struct
pub const Score = @import("Score.zig").Score;

pub const Offset = @import("Offset.zig").Offset;
pub const Bitboard = @import("Bitboard.zig").Bitboard;
pub const Position = @import("Position.zig").Position;
pub const Move = @import("Move.zig").Move;

// allows `zig build test` to work
test {
    @import("std").testing.refAllDecls(@This());
}