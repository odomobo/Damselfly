const std = @import("std");
const df = @import("../damselfly.zig");

const Bitboard = df.types.Bitboard;
const Position = df.types.Position;
const Piece = df.types.Piece;
const Move = df.types.Move;
const bits = df.bits;
const assert = std.debug.assert;

pub const CanCastle = packed struct(u8) {
    const Self = @This();

    const whiteKingsideMask = Bitboard.fromStr(
        " . . . . . . . . / " ++
        " . . . . . . . . / " ++
        " . . . . . . . . / " ++
        " . . . . . . . . / " ++
        " . . . . . . . . / " ++
        " . . . . . . . . / " ++
        " . . . . . . . . / " ++
        " . . . . O . . O   "
    );

    const whiteQueensideMask = Bitboard.fromStr(
        " . . . . . . . . / " ++
        " . . . . . . . . / " ++
        " . . . . . . . . / " ++
        " . . . . . . . . / " ++
        " . . . . . . . . / " ++
        " . . . . . . . . / " ++
        " . . . . . . . . / " ++
        " O . . . O . . .   "
    );

    const blackKingsideMask = Bitboard.fromStr(
        " . . . . O . . O / " ++
        " . . . . . . . . / " ++
        " . . . . . . . . / " ++
        " . . . . . . . . / " ++
        " . . . . . . . . / " ++
        " . . . . . . . . / " ++
        " . . . . . . . . / " ++
        " . . . . . . . .   "
    );

    const blackQueensideMask = Bitboard.fromStr(
        " O . . . O . . . / " ++
        " . . . . . . . . / " ++
        " . . . . . . . . / " ++
        " . . . . . . . . / " ++
        " . . . . . . . . / " ++
        " . . . . . . . . / " ++
        " . . . . . . . . / " ++
        " . . . . . . . .   "
    );

    whiteKingside: bool,
    whiteQueenside: bool,
    blackKingside: bool,
    blackQueenside: bool,
    _: u4 = 0,

    pub fn fromStr(str: []const u8) Self {
        return tryFromStr(str) catch unreachable;
    }

    pub fn tryFromStr(str: []const u8) Position.Error!Self {
        if(str.len == 0)
            return Position.Error.FenInvalid;
        
        var ret = Self{.whiteKingside = false, .whiteQueenside = false, .blackKingside = false, .blackQueenside = false};

        if (std.mem.eql(u8, "-", str))
            return ret;
        
        for (str) |c| {
            switch (c) {
                'K' => ret.whiteKingside = true,
                'Q' => ret.whiteQueenside = true,
                'k' => ret.blackKingside = true,
                'q' => ret.blackQueenside = true,
                else => return Position.Error.FenInvalid,
            }
        }

        return ret;
    }

    pub fn fixCastlingFromPosition(self: *Self, pos: *Position) void {
        if (pos.getIndexPiece(bits.strToIndex("e1")).neql(Piece.WhiteKing))
        {
            self.whiteKingside = false;
            self.whiteQueenside = false;
        }

        if (pos.getIndexPiece(bits.strToIndex("h1")).neql(Piece.WhiteRook))
            self.whiteKingside = false;

        if (pos.getIndexPiece(bits.strToIndex("a1")).neql(Piece.WhiteRook))
            self.whiteQueenside = false;


        if (pos.getIndexPiece(bits.strToIndex("e8")).neql(Piece.BlackKing))
        {
            self.blackKingside = false;
            self.blackQueenside = false;
        }

        if (pos.getIndexPiece(bits.strToIndex("h8")).neql(Piece.BlackRook))
            self.blackKingside = false;

        if (pos.getIndexPiece(bits.strToIndex("a8")).neql(Piece.BlackRook))
            self.blackQueenside = false;
    }

    pub fn updateCastlingFromMove(self: *Self, move: Move) void {
        var moveBb = Bitboard{ .val = 0 };
        moveBb.setIndex(move.srcIndex);
        moveBb.setIndex(move.dstIndex);

        if (moveBb.val & whiteKingsideMask.val != 0)
            self.whiteKingside = false;

        if (moveBb.val & whiteQueensideMask.val != 0)
            self.whiteQueenside = false;
        
        if (moveBb.val & blackKingsideMask.val != 0)
            self.blackKingside = false;

        if (moveBb.val & blackQueensideMask.val != 0)
            self.blackQueenside = false;
    }

    pub fn format(self: Self, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void
    {
        var any = false;
        if (self.whiteKingside) {
            any = true;
            try writer.print("K", .{});
        }
        if (self.whiteQueenside) {
            any = true;
            try writer.print("Q", .{});
        }
        if (self.blackKingside) {
            any = true;
            try writer.print("k", .{});
        }
        if (self.blackQueenside) {
            any = true;
            try writer.print("q", .{});
        }
        if (!any)
        {
            try writer.print("-", .{});
        }
    }
};