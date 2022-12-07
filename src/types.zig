const df = @import("damselfly.zig");

pub const Color = @import("types/Color.zig").Color;
pub const PieceType = @import("types/PieceType.zig").PieceType;
pub const Piece = @import("types/Piece.zig").Piece;

pub const Offset = @import("types/Offset.zig").Offset;
pub const Position = @import("types/Position.zig").Position;
pub const Move = @import("types/Move.zig").Move;
pub const CanCastle = @import("types/CanCastle.zig").CanCastle;
pub const Bitboard = u64;
pub const Index = u6;
pub const Score = i16;
pub const ZobristHash = u64;

pub const MoveList = df.StaticArrayList(Move, df.constants.maxNumberOfMoves);

// allows `zig build test` to work
test {
    @import("std").testing.refAllDecls(@This());
}