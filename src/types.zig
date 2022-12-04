const df = @import("damselfly.zig");

pub const Color = @import("types/Color.zig").Color;
pub const PieceType = @import("types/PieceType.zig").PieceType;
pub const Piece = @import("types/Piece.zig").Piece;
pub const Score = @import("types/Score.zig").Score;

pub const Offset = @import("types/Offset.zig").Offset;
pub const Bitboard = @import("types/Bitboard.zig").Bitboard;
pub const Position = @import("types/Position.zig").Position;
pub const Move = @import("types/Move.zig").Move;
pub const CanCastle = @import("types/CanCastle.zig").CanCastle;

pub const MoveList = df.StaticArrayList(Move, 256);

// allows `zig build test` to work
test {
    @import("std").testing.refAllDecls(@This());
}