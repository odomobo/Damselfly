const std = @import("std");
const df = @import("../damselfly.zig");

const assert = std.debug.assert;
const eql = std.meta.eql;

const Bitboard = df.types.Bitboard;
const bitboards = df.bitboards;
const Position = df.types.Position;
const Piece = df.types.Piece;
const Move = df.types.Move;
const indexes = df.indexes;
const castling = df.tables.castling;

pub const CanCastle = packed struct(u8) {
    const Self = @This();

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
        if (!eql(pos.getIndexPiece(indexes.strToIndex("e1")), Piece.WhiteKing))
        {
            self.whiteKingside = false;
            self.whiteQueenside = false;
        }

        if (!eql(pos.getIndexPiece(indexes.strToIndex("h1")), Piece.WhiteRook))
            self.whiteKingside = false;

        if (!eql(pos.getIndexPiece(indexes.strToIndex("a1")), Piece.WhiteRook))
            self.whiteQueenside = false;


        if (!eql(pos.getIndexPiece(indexes.strToIndex("e8")), Piece.BlackKing))
        {
            self.blackKingside = false;
            self.blackQueenside = false;
        }

        if (!eql(pos.getIndexPiece(indexes.strToIndex("h8")), Piece.BlackRook))
            self.blackKingside = false;

        if (!eql(pos.getIndexPiece(indexes.strToIndex("a8")), Piece.BlackRook))
            self.blackQueenside = false;
    }

    pub fn updateCastlingFromMove(self: *Self, move: Move) void {
        var moveBb: Bitboard = 0;
        bitboards.setIndex(&moveBb, move.srcIndex);
        bitboards.setIndex(&moveBb, move.dstIndex);

        if (moveBb & castling.whiteKingsidePieceMask != 0)
            self.whiteKingside = false;

        if (moveBb & castling.whiteQueensidePieceMask != 0)
            self.whiteQueenside = false;
        
        if (moveBb & castling.blackKingsidePieceMask != 0)
            self.blackKingside = false;

        if (moveBb & castling.blackQueensidePieceMask != 0)
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