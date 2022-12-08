const std = @import("std");
const df = @import("../damselfly.zig");

const assert = std.debug.assert;
const assertDebug = df.debug.assertDebug;
const assertParanoid = df.debug.assertParanoid;
const eql = std.meta.eql;

const Bitboard = df.types.Bitboard;
const CanCastle = df.types.CanCastle;
const Offset = df.types.Offset;
const Move = df.types.Move;
const Piece = df.types.Piece;
const PieceType = df.types.PieceType;
const Color = df.types.Color;
const indexes = df.indexes;
const bitboards = df.bitboards;
const movements = df.tables.movements;
const Index = df.types.Index;
const ZobristHash = df.types.ZobristHash;

pub const Position = struct {
    const Self = @This();

    pub const Error = error {
        FenInvalid,
    };

    occupied: Bitboard,
    occupiedColors: [2]Bitboard,
    occupiedPieces: [6]Bitboard,
    inCheck: bool,
    parent: ?*const Self,
    sideToMove: Color,
    enPassant: ?Index,
    canCastle: CanCastle,
    fiftyMoveCounter: isize, // resets to 0 after pawn move or capture; this is in number of plies
    gamePly: isize, // game's ply, starting from 0
    zobristHash: ZobristHash,
    lastMoveWasReversible: bool,

    pub const empty = Self {
        .occupied = 0,
        .occupiedColors = [_]Bitboard{0} ** 2,
        .occupiedPieces = [_]Bitboard{0} ** 6,
        .inCheck = false,
        .parent = null,
        .sideToMove = Color.White,
        .enPassant = null,
        .canCastle = CanCastle{.whiteKingside = false, .whiteQueenside = false, .blackKingside = false, .blackQueenside = false},
        .fiftyMoveCounter = 0,
        .gamePly = 0,
        .zobristHash = 0,
        .lastMoveWasReversible = false,
    };

    pub fn fromFen(fen: []const u8) !Position {
        var ret = Position.empty;

        var splitFen = std.mem.split(u8, fen, " ");

        var pieces = splitFen.first();
        var x: isize = 0;
        var y: isize = 7;
        for (pieces) |c| {
            var maybePiece = Piece.maybeFromChar(c);
            if (maybePiece) |piece| {
                if (x >= 8)
                    return Error.FenInvalid;
                if (y < 0)
                    return Error.FenInvalid;

                ret.setXYPiece(x, y, piece);
                x += 1;
                continue;
            }

            if (c >= '1' and c <= '8')
            {
                x += @intCast(isize, c - '0');
                if (x > 8)
                    return Error.FenInvalid;
                if (y < 0)
                    return Error.FenInvalid;

                continue;
            }

            if (c == '/')
            {
                if (x != 8)
                    return Error.FenInvalid;
                if (y <= 0)
                    return Error.FenInvalid;
                
                x = 0;
                y -= 1;
                continue;
            }

            return Error.FenInvalid;
        }

        if (x != 8 or y != 0)
            return Error.FenInvalid;

        // if not 1 white king and not 1 black king, then FEN is invalid
        if (bitboards.popCount(ret.getPieceBb(Color.White, PieceType.King)) != 1)
            return Error.FenInvalid;

        if (bitboards.popCount(ret.getPieceBb(Color.Black, PieceType.King)) != 1)
            return Error.FenInvalid;

        var maybeSideToMove = splitFen.next();
        if (maybeSideToMove == null)
            return Error.FenInvalid;

        if (std.mem.eql(u8, "w", maybeSideToMove.?)) {
            ret.sideToMove = Color.White;
        } else if (std.mem.eql(u8, "b", maybeSideToMove.?)) {
            ret.sideToMove = Color.Black;
        } else {
            return Error.FenInvalid;
        }

        // if for the position, the side not to move is in check, it's not a valid position because that means we could capture their king on this move.
        if (ret.isOtherKingInCheck())
            return Error.FenInvalid;

        var maybeCastlingAbility = splitFen.next();
        if (maybeCastlingAbility == null)
            return Error.FenInvalid;
        
        ret.canCastle = try CanCastle.tryFromStr(maybeCastlingAbility.?);
        ret.canCastle.fixCastlingFromPosition(&ret); // this just needs to get called after the pieces are set

        var maybeEpSquare = splitFen.next();
        if (maybeEpSquare == null)
            return Error.FenInvalid;
        
        if (std.mem.eql(u8, "-", maybeEpSquare.?)) {
            ret.enPassant = null;
        } else {
            ret.enPassant = try indexes.tryStrToIndex(maybeEpSquare.?);
        }

        var maybeHalfmoveClock = splitFen.next();
        if (maybeHalfmoveClock) |halfmoveClock| {
            _ = halfmoveClock;
            // TODO: extract
        }

        var maybeFullmoveCounter = splitFen.next();
        if (maybeFullmoveCounter) |fullmoveCounter| {
            _ = fullmoveCounter;
            // TODO extract
        }

        // TODO: should we do this check?
        var maybeExtra = splitFen.next();
        if (maybeExtra != null)
            return Error.FenInvalid;

        ret.calculateInCheck();

        ret.zobristHash = df.tables.zobrist.getZobristHashForPosition(&ret);

        return ret;
    }

    pub fn makeFromMove(parent: *const Self, move: Move) Self {
        var ret: Self = parent.*;
        
        ret.parent = parent;
        ret.enPassant = null;
        ret.fiftyMoveCounter += 1;
        ret.gamePly += 1;
        ret.lastMoveWasReversible = false; // all the special cases are non-reversible; only normal quiet moves are reversible

        var moveType = move.moveType;
        if (moveType == .Normal and !move.capture) {
            ret.makeNormalQuietMove(move);
            if (move.pieceType != .Pawn) {
                ret.lastMoveWasReversible = true;
            }
        } else if (moveType == .Normal and move.capture) {
            ret.makeNormalCaptureMove(move);
        } else if (moveType == .DoubleMove and !move.capture) {
            ret.makeDoublePawnMove(move);
        } else if (moveType == .EnPassant and move.capture) {
            ret.makeEnPassantMove(move);
        } else if (moveType == .Promotion and !move.capture) {
            ret.makePromotionQuietMove(move);
        } else if (moveType == .Promotion and move.capture) {
            ret.makePromotionCaptureMove(move);
        } else if (moveType == .Castling and !move.capture) {
            ret.makeCastlingMove(move);
        } else {
            unreachable;
        }

        ret.canCastle.updateCastlingFromMove(move);

        // swap side to move only _after_ making the move
        ret.sideToMove = parent.sideToMove.other();

        // this depends on move being made, side-to-move being updated, castling being updated, and en passant square being set
        // TODO: maybe incremental update?
        ret.zobristHash = df.tables.zobrist.getZobristHashForPosition(&ret);

        // TODO: calculate repetition number

        // if the castling rights have changed, then the move wasn't reversible
        if (!eql(ret.canCastle, parent.canCastle)) {
            ret.lastMoveWasReversible = false;
        }

        // reset 50 move rule on capture or pawn move, which is slightly different from non-reversible moves
        if (move.capture or move.pieceType == .Pawn)
            ret.fiftyMoveCounter = 0;

        ret.calculateInCheck();

        return ret;
    }

    fn movePiece(self: *Self, srcIndex: Index, dstIndex: Index, pieceType: PieceType) void {
        var piece = Piece.init(self.sideToMove, pieceType);

        self.clearIndex(srcIndex);
        self.setIndexPiece(dstIndex, piece);
    }

    fn makeNormalQuietMove(self: *Self, move: Move) void {
        self.movePiece(move.srcIndex, move.dstIndex, move.pieceType);
    }

    fn makeNormalCaptureMove(self: *Self, move: Move) void {
        self.clearIndex(move.dstIndex);
        self.movePiece(move.srcIndex, move.dstIndex, move.pieceType);
        self.fiftyMoveCounter = 0;
    }

    fn makeDoublePawnMove(self: *Self, move: Move) void {
        self.movePiece(move.srcIndex, move.dstIndex, move.pieceType);
        self.enPassant = @intCast(Index, @divExact(@intCast(usize, move.srcIndex) + @intCast(usize, move.dstIndex), 2) );
        self.fiftyMoveCounter = 0;
    }

    fn makeEnPassantMove(self: *Self, move: Move) void {
        var srcXY = indexes.indexToXY(move.srcIndex);
        var dstXY = indexes.indexToXY(move.dstIndex);

        self.clearXY(dstXY.x, srcXY.y);
        self.movePiece(move.srcIndex, move.dstIndex, move.pieceType);
        self.fiftyMoveCounter = 0;
    }

    fn makePromotionQuietMove(self: *Self, move: Move) void {
        self.clearIndex(move.srcIndex); // TODO: could make more efficient by including pawn as the piece to clear
        self.setIndexPiece(move.dstIndex, Piece.init(self.sideToMove, move.promotionPieceType)); // TODO: could make more efficient by including pawn as the piece to move
        self.fiftyMoveCounter = 0;
    }

    fn makePromotionCaptureMove(self: *Self, move: Move) void {
        self.clearIndex(move.srcIndex); // TODO: could make more efficient by including pawn as the piece to clear
        self.clearIndex(move.dstIndex);
        self.setIndexPiece(move.dstIndex, Piece.init(self.sideToMove, move.promotionPieceType));
        self.fiftyMoveCounter = 0;
    }

    fn makeCastlingMove(self: *Self, move: Move) void {
        if (move.srcIndex == indexes.strToIndex("e1")) {
            self.clearIndex(indexes.strToIndex("e1"));
            if (move.dstIndex == indexes.strToIndex("g1")) {
                self.clearIndex(indexes.strToIndex("h1"));
                self.setIndexPiece(indexes.strToIndex("f1"), Piece.WhiteRook);
                self.setIndexPiece(indexes.strToIndex("g1"), Piece.WhiteKing);
            } else if (move.dstIndex == indexes.strToIndex("c1")) {
                self.clearIndex(indexes.strToIndex("a1"));
                self.setIndexPiece(indexes.strToIndex("d1"), Piece.WhiteRook);
                self.setIndexPiece(indexes.strToIndex("c1"), Piece.WhiteKing);
            } else {
                unreachable;
            }
        } else if (move.srcIndex == indexes.strToIndex("e8")) {
            self.clearIndex(indexes.strToIndex("e8"));
            if (move.dstIndex == indexes.strToIndex("g8")) {
                self.clearIndex(indexes.strToIndex("h8"));
                self.setIndexPiece(indexes.strToIndex("f8"), Piece.BlackRook);
                self.setIndexPiece(indexes.strToIndex("g8"), Piece.BlackKing);
            } else if (move.dstIndex == indexes.strToIndex("c8")) {
                self.clearIndex(indexes.strToIndex("a8"));
                self.setIndexPiece(indexes.strToIndex("d8"), Piece.BlackRook);
                self.setIndexPiece(indexes.strToIndex("c8"), Piece.BlackKing);
            } else {
                unreachable;
            }
        } else {
            unreachable;
        }
    }

    fn calculateInCheck(self: *Self) void {
        var kingSquare = self.getPieceBb(self.sideToMove, PieceType.King);
        assert(bitboards.popCount(kingSquare) == 1); // this is good to always do, I think? this should never be false, but would be catastrophic if it was
        self.inCheck = self.isSquareAttacked(self.sideToMove, kingSquare);
    }

    pub fn isOtherKingInCheck(self: *const Self) bool {
        var kingSquare = self.getPieceBb(self.sideToMove.other(), PieceType.King);
        assert(bitboards.popCount(kingSquare) == 1); // this is good to always do, I think? this should never be false, but would be catastrophic if it was
        return self.isSquareAttacked(self.sideToMove.other(), kingSquare);
    }

    pub fn isSquareAttacked(self: *const Self, color: Color, square: Bitboard) bool {
        assertDebug(bitboards.popCount(square) == 1);

        switch (color) {
            inline else => |comptimeColor| {
                // we use the current color for pawn captures, because we're checking in the opposite direction of the pawn's real capture direction
                if (self.isSquareAttackedWithOffsetPieceSlider(comptimeColor, square, movements.pawnCaptures(comptimeColor), &[_]PieceType{PieceType.Pawn}, false))
                    return true;
            }
        }

        if (self.isSquareAttackedWithOffsetPieceSlider(color, square, movements.byPieceType(PieceType.Knight), &[_]PieceType{PieceType.Knight}, false))
            return true;
        
        if (self.isSquareAttackedWithOffsetPieceSlider(color, square, movements.byPieceType(PieceType.Rook), &[_]PieceType{PieceType.Rook, PieceType.Queen}, true))
            return true;

        if (self.isSquareAttackedWithOffsetPieceSlider(color, square, movements.byPieceType(PieceType.Bishop), &[_]PieceType{PieceType.Bishop, PieceType.Queen}, true))
            return true;

        if (self.isSquareAttackedWithOffsetPieceSlider(color, square, movements.byPieceType(PieceType.King), &[_]PieceType{PieceType.King}, false))
            return true;

        return false;
    }

    fn isSquareAttackedWithOffsetPieceSlider(self: *const Self, color: Color, square: Bitboard, comptime offsets: []const Offset, comptime pieceTypes: []const PieceType, comptime isSlider: bool) bool {
        assertDebug(bitboards.popCount(square) == 1);
        const occupied = self.occupied;
        const otherOccupied = self.getColorBb(color.other());

        for (offsets) |offset| {
            var currentSquare = square;
            while (true) {
                if (!offset.isAllowedFrom(currentSquare))
                    break;
                
                currentSquare = bitboards.getWithOffset(currentSquare, offset);
                if (currentSquare & otherOccupied != 0)
                {
                    inline for (pieceTypes) |pieceType| {
                        if (currentSquare & self.getPieceBb(color.other(), pieceType) != 0) {
                            return true;
                        }
                    }

                    // if it wasn't any of those, then we can't continue in this direction.
                    break;
                }

                // hit our own piece
                if (currentSquare & occupied != 0)
                    break;

                // this shouldn't be a loop if it's not a slider
                if (!isSlider)
                    break;
            }
        }

        return false;
    }

    pub fn getXYPiece(self: *const Self, x: isize, y: isize) Piece {
        return self.getIndexPiece(indexes.xyToIndex(x, y));
    }

    pub fn getIndexPiece(self: *const Self, index: Index) Piece {
        var square = indexes.indexToBit(index);
        if (square & self.occupied == 0)
            return Piece.None;
        
        var color: Color = undefined;
        if (self.getColorBb(.White) & square != 0) {
            color = .White;
        } else if (self.getColorBb(.Black) & square != 0) {
            color = .Black;
        } else {
            unreachable;
        }

        var pieceType: PieceType = undefined;
        if (self.getPieceTypeBb(.Pawn) & square != 0) {
            pieceType = .Pawn;
        } else if (self.getPieceTypeBb(.Knight) & square != 0) {
            pieceType = .Knight;
        } else if (self.getPieceTypeBb(.Bishop) & square != 0) {
            pieceType = .Bishop;
        } else if (self.getPieceTypeBb(.Rook) & square != 0) {
            pieceType = .Rook;
        } else if (self.getPieceTypeBb(.Queen) & square != 0) {
            pieceType = .Queen;
        } else if (self.getPieceTypeBb(.King) & square != 0) {
            pieceType = .King;
        } else {
            unreachable;
        }

        return Piece.init(color, pieceType);
    }

    pub fn setXYPiece(self: *Self, x: isize, y: isize, piece: Piece) void {
        self.setIndexPiece(indexes.xyToIndex(x, y), piece);
    }

    pub fn setIndexPiece(self: *Self, index: Index, piece: Piece) void {
        assert(self.getIndexPiece(index).getPieceType() == PieceType.None);
        
        var pieceType = piece.getPieceType();
        assert(pieceType != PieceType.None); // This isn't allowed; must only use clear instead.
        var color = piece.getColor();

        bitboards.setIndex(&self.occupied, index);
        bitboards.setIndex(&self.occupiedColors[@enumToInt(color)], index);
        bitboards.setIndex(&self.occupiedPieces[@enumToInt(pieceType)], index);
    }

    pub fn clearXY(self: *Self, x: isize, y: isize) void {
        self.clearIndex(indexes.xyToIndex(x, y));
    }

    pub fn clearIndex(self: *Self, index: Index) void {
        assert(self.getIndexPiece(index).getPieceType() != PieceType.None);

        bitboards.clearIndex(&self.occupied, index);
        // TODO: maybe can make this more efficient
        inline for (self.occupiedColors) |*square| {
            bitboards.clearIndex(square, index);
        }
        inline for (self.occupiedPieces) |*square| {
            bitboards.clearIndex(square, index);
        }
    }

    pub fn getPieceBb(self: *const Self, color: Color, pieceType: PieceType) Bitboard {
        assert(pieceType != PieceType.None);
        return self.occupiedColors[@enumToInt(color)] & self.occupiedPieces[@enumToInt(pieceType)];
    }

    pub fn getPieceTypeBb(self: *const Self, pieceType: PieceType) Bitboard {
        assert(pieceType != PieceType.None);
        return self.occupiedPieces[@enumToInt(pieceType)];
    }

    pub fn getColorBb(self: *const Self, color: Color) Bitboard {
        return self.occupiedColors[@enumToInt(color)];
    }

    pub fn format(self: *const Self, comptime fmt: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void
    {
        if (comptime std.mem.eql(u8, fmt, "short"))
        {
            var y: isize = 7;
            while(y >= 0) : (y -= 1)
            {
                var x: isize = 0;
                while(x < 8) : (x += 1)
                {
                    try writer.print(" {short}", .{self.getXYPiece(x, y)});
                }
                try writer.print("\n", .{});
            }
            try writer.print("Side to move: {full}\n", .{self.sideToMove});
            if (self.inCheck)
                try writer.print("In check.\n", .{});
            try writer.print("Castling rights: {}\n", .{self.canCastle});
            try writer.print("En passant square: {}\n", .{indexes.indexToFormattable(self.enPassant)});
            try writer.print("Zobrist Hash: 0x{X:0>16}\n", .{self.zobristHash});
        }
        else 
        {
            @compileError("format type for Piece must be \"short\" for now...");
        }
    }

};