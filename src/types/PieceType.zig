const std = @import("std");
const df = @import("../damselfly.zig");

pub const PieceType = enum(u3) {
    const Self = @This();

    Pawn = 0,
    Knight = 1,
    Bishop = 2,
    Rook = 3,
    Queen = 4,
    King = 5,
    None = 6,

    pub fn format(self: Self, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void
    {
        switch (self) {
            Self.Pawn => try writer.print("Pawn", .{}),
            Self.Knight => try writer.print("Knight", .{}),
            Self.Bishop => try writer.print("Bishop", .{}),
            Self.Rook => try writer.print("Rook", .{}),
            Self.Queen => try writer.print("Queen", .{}),
            Self.King => try writer.print("King", .{}),
            Self.None => try writer.print("None", .{}),
        }
    }
};