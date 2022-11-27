
pub const Color = @import("Color.zig").Color;
pub const PieceType = @import("PieceType.zig").PieceType;
pub const Piece = @import("Piece.zig");
usingnamespace @import("score.zig");


// allows `zig build test` to work
test {
    @import("std").testing.refAllDecls(@This());
}