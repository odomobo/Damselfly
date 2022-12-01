const std = @import("std");
const df = @import("../damselfly.zig");

const Color = df.types.Color;
const PieceType = df.types.PieceType;

pub const Piece = struct {
    const Self = @This();

    pub const BackingType = u8;

    pub const None = Self.init(Color.White, PieceType.None);
    pub const WhitePawn = Self.init(Color.White, PieceType.Pawn);
    pub const WhiteKnight = Self.init(Color.White, PieceType.Knight);
    pub const WhiteBishop = Self.init(Color.White, PieceType.Bishop);
    pub const WhiteRook = Self.init(Color.White, PieceType.Rook);
    pub const WhiteQueen = Self.init(Color.White, PieceType.Queen);
    pub const WhiteKing = Self.init(Color.White, PieceType.King);
    pub const BlackPawn = Self.init(Color.Black, PieceType.Pawn);
    pub const BlackKnight = Self.init(Color.Black, PieceType.Knight);
    pub const BlackBishop = Self.init(Color.Black, PieceType.Bishop);
    pub const BlackRook = Self.init(Color.Black, PieceType.Rook);
    pub const BlackQueen = Self.init(Color.Black, PieceType.Queen);
    pub const BlackKing = Self.init(Color.Black, PieceType.King);

    data: BackingType, // TODO: use packed struct instead of this

    pub fn init(color: Color, pieceType: PieceType) Self {
        return Self{ .data = @enumToInt(color) | @enumToInt(pieceType)};
    }

    pub fn maybeFromChar(c: u8) ?Self {
        return switch (c) {
            'P' => Self.init(Color.White, PieceType.Pawn),
            'N' => Self.init(Color.White, PieceType.Knight),
            'B' => Self.init(Color.White, PieceType.Bishop),
            'R' => Self.init(Color.White, PieceType.Rook),
            'Q' => Self.init(Color.White, PieceType.Queen),
            'K' => Self.init(Color.White, PieceType.King),
            'p' => Self.init(Color.Black, PieceType.Pawn),
            'n' => Self.init(Color.Black, PieceType.Knight),
            'b' => Self.init(Color.Black, PieceType.Bishop),
            'r' => Self.init(Color.Black, PieceType.Rook),
            'q' => Self.init(Color.Black, PieceType.Queen),
            'k' => Self.init(Color.Black, PieceType.King),
            else => null,
        };
    }

    pub fn getColor(self: Self) Color {
        return @intToEnum(Color, self.data & 0b1000);
    }

    pub fn getPieceType(self: Self) PieceType {
        return @intToEnum(PieceType, self.data & 0b0111);
    }

    pub fn eql(self: Self, other: Self) bool {
        return self.data == other.data;
    }

    pub fn neql(self: Self, other: Self) bool {
        return self.data != other.data;
    }

    pub fn deconstruct(self: Self, color: *Color, pieceType: *PieceType) void {
        color.* = self.getColor();
        pieceType.* = self.getPieceType();
    }

    pub fn format(self: Self, comptime fmt: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void
    {
        if (comptime std.mem.eql(u8, fmt, "short"))
        {
            if (self.getColor() == Color.White)
            {
                switch (self.getPieceType()) {
                    PieceType.Pawn => try writer.print("P", .{}),
                    PieceType.Bishop => try writer.print("B", .{}),
                    PieceType.Knight => try writer.print("N", .{}),
                    PieceType.Rook => try writer.print("R", .{}),
                    PieceType.Queen => try writer.print("Q", .{}),
                    PieceType.King => try writer.print("K", .{}),
                    PieceType.None => try writer.print(".", .{}),
                }
            }
            else
            {
                switch (self.getPieceType()) {
                    PieceType.Pawn => try writer.print("p", .{}),
                    PieceType.Bishop => try writer.print("b", .{}),
                    PieceType.Knight => try writer.print("n", .{}),
                    PieceType.Rook => try writer.print("r", .{}),
                    PieceType.Queen => try writer.print("q", .{}),
                    PieceType.King => try writer.print("k", .{}),
                    PieceType.None => try writer.print("!", .{}),
                }
            }
        }
        else if (comptime std.mem.eql(u8, fmt, "full"))
        {
            if (self.getPieceType() == PieceType.None)
            {
                try writer.print("{}", .{self.getPieceType()});
            }
            else
            {
                try writer.print("{}{}", .{self.getColor(), self.getPieceType()});
            }
        }
        else 
        {
            @compileError("format type for Piece must be either \"short\" or \"full\"");
        }
    }
};

// tests

test "Piece.eql" {
    var k = Piece.init(Color.Black, PieceType.King);
    var K = Piece.init(Color.White, PieceType.King);
    var b = Piece.init(Color.Black, PieceType.Bishop);
    var none = Piece.None;

    try std.testing.expect(k.eql(k));
    try std.testing.expect(none.eql(none));
    try std.testing.expect(!k.eql(K));
    try std.testing.expect(!k.eql(b));
    try std.testing.expect(!k.eql(none));
    try std.testing.expect(!K.eql(k));
    try std.testing.expect(!b.eql(k));
    try std.testing.expect(!none.eql(k));
}

test "Piece.neql" {
    var k = Piece.init(Color.Black, PieceType.King);
    var K = Piece.init(Color.White, PieceType.King);
    var b = Piece.init(Color.Black, PieceType.Bishop);
    var none = Piece.None;

    try std.testing.expect(!k.neql(k));
    try std.testing.expect(!none.neql(none));
    try std.testing.expect(k.neql(K));
    try std.testing.expect(k.neql(b));
    try std.testing.expect(k.neql(none));
    try std.testing.expect(K.neql(k));
    try std.testing.expect(b.neql(k));
    try std.testing.expect(none.neql(k));
}

test "Piece.getColor" {
    var k = Piece.init(Color.Black, PieceType.King);
    var K = Piece.init(Color.White, PieceType.King);
    var b = Piece.init(Color.Black, PieceType.Bishop);

    try std.testing.expectEqual(Color.Black, k.getColor());
    try std.testing.expectEqual(Color.White, K.getColor());
    try std.testing.expectEqual(Color.Black, b.getColor());
}

test "Piece.getPieceType" {
    var k = Piece.init(Color.Black, PieceType.King);
    var K = Piece.init(Color.White, PieceType.King);
    var b = Piece.init(Color.Black, PieceType.Bishop);
    var none = Piece.None;

    try std.testing.expectEqual(PieceType.King, k.getPieceType());
    try std.testing.expectEqual(PieceType.King, K.getPieceType());
    try std.testing.expectEqual(PieceType.Bishop, b.getPieceType());
    try std.testing.expectEqual(PieceType.None, none.getPieceType());
}

test "Piece.deconstruct" {
    var k = Piece.init(Color.Black, PieceType.King);

    var pieceType: PieceType = undefined;
    var color: Color = undefined;

    k.deconstruct(&color, &pieceType);

    try std.testing.expectEqual(PieceType.King, pieceType);
    try std.testing.expectEqual(Color.Black, color);
}

test "Piece.format" {
    var k = Piece.init(Color.Black, PieceType.King);
    var K = Piece.init(Color.White, PieceType.King);
    var b = Piece.init(Color.Black, PieceType.Bishop);
    var none = Piece.None;

    try std.testing.expectFmt("k", "{short}", .{k});
    try std.testing.expectFmt("K", "{short}", .{K});
    try std.testing.expectFmt("b", "{short}", .{b});
    try std.testing.expectFmt(".", "{short}", .{none});

    try std.testing.expectFmt("BlackKing", "{full}", .{k});
    try std.testing.expectFmt("WhiteKing", "{full}", .{K});
    try std.testing.expectFmt("BlackBishop", "{full}", .{b});
    try std.testing.expectFmt("None", "{full}", .{none});
}
