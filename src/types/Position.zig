const std = @import("std");
const df = @import("../damselfly.zig");

const assert = std.debug.assert;
const Bitboard = df.types.Bitboard;
const CanCastle = df.types.CanCastle;
const Offset = df.types.Offset;
const Move = df.types.Move;
const Piece = df.types.Piece;
const PieceType = df.types.PieceType;
const Color = df.types.Color;
const bits = df.bits;

pub const Position = struct {
    const Self = @This();

    pub const Error = error {
        FenInvalid,
    };

    occupied: Bitboard,
    occupiedWhite: Bitboard,
    occupiedPieces: [6]Bitboard,
    inCheck: [2]?bool = [2]?bool{null, null},
    squares: [64]Piece, // TODO: get rid of this? need to benchmark I guess
    parent: ?*Self,
    sideToMove: Color,
    enPassant: ?isize,
    canCastle: CanCastle, // TODO: include this when castling rights type is implemented
    fiftyMoveCounter: isize, // resets to 0 after pawn move or capture; this is in number of plies
    gamePly: isize, // game's ply, starting from 0
    historyPly: isize, // similar to game ply, but from the position we started from, not from the initial position in the game
    // zobristHash: ZobristHash, // TODO: include this when zobrist hash type is implemented
    repetitionNumber: isize, // TODO: this depends on zobrist hash; 1 means this the first time it's been seen

    pub const empty = Self {
        .occupied = Bitboard.empty,
        .occupiedWhite = Bitboard.empty,
        .occupiedPieces = [_]Bitboard{Bitboard.empty} ** 6,
        .squares = [_]Piece{Piece.None} ** 64,
        .parent = null,
        .sideToMove = Color.White,
        .enPassant = null,
        .canCastle = CanCastle{.whiteKingside = false, .whiteQueenside = false, .blackKingside = false, .blackQueenside = false},
        .fiftyMoveCounter = 0,
        .gamePly = 0,
        .historyPly = 0,
        .repetitionNumber = 1,
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

        var maybeSideToMove = splitFen.next();
        if (maybeSideToMove == null)
            return Error.FenInvalid;
        
        if (std.mem.eql(u8, "w", maybeSideToMove.?)) {
            ret.sideToMove = Color.White;
        } else if (std.mem.eql(u8, "b", maybeSideToMove.?)) {
            ret.sideToMove = Color.White;
        } else {
            return Error.FenInvalid;
        }

        var maybeCastlingAbility = splitFen.next();
        if (maybeCastlingAbility == null)
            return Error.FenInvalid;
        
        ret.canCastle = try CanCastle.tryFromStr(maybeCastlingAbility.?);
        ret.canCastle.fixCastlingFromPosition(&ret); // this just needs to get called after the pieces are set

        var maybeEpSquare = splitFen.next();
        if (maybeEpSquare == null)
            return Error.FenInvalid;
        
        // TODO: extract

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

        return ret;
    }

    pub fn makeFromMove(parent: *const Self, move: Move) Self {
        var ret: Self = parent.*;

        ret.parent = parent;
        ret.inCheck = [_]?bool{null, null}; // TODO: can use .{null, null} ?
        ret.sideToMove = parent.sideToMove.other();
        ret.enPassant = null;
        ret.fiftyMoveCounter += 1;
        ret.gamePly += 1;
        ret.historyPly += 1;

        var moveType = move.moveType;
        if (moveType.normal and moveType.quiet) {
            ret.makeNormalQuietMove(move);
        } else if (moveType.normal and moveType.capture) {
            ret.makeNormalCaptureMove(move);
        } else if (moveType.doubleMove and moveType.quiet) {
            ret.makeDoublePawnMove(move);
        } else if (moveType.enPassant and moveType.capture) {
            ret.makeEnPassantMove(move);
        } else if (moveType.promotion and moveType.quiet) {
            ret.makePromotionQuietMove(move);
        } else if (moveType.castling and moveType.quiet) {
            ret.makeCastlingMove(move);
        } else {
            unreachable;
        }

        ret.canCastle.updateCastlingFromMove(move);

        // TODO: zobrist hash

        // TODO: calculate repetition number

        // TODO: update 50 move rule

        return ret;
    }

    fn movePiece(self: *Self, srcIndex: isize, dstIndex: isize) void {
        var piece = self.squares[srcIndex];
        assert(piece.getPieceType() != PieceType.None);

        self.clearIndex(srcIndex);
        self.setIndexPiece(dstIndex, piece);
    }

    fn makeNormalQuietMove(self: *Self, move: Move) void {
        self.movePiece(move.srcIndex, move.dstIndex);
    }

    fn makeNormalCaptureMove(self: *Self, move: Move) void {
        self.clearIndex(move.dstIndex);
        self.movePiece(move.srcIndex, move.dstIndex);
        self.fiftyMoveCounter = 0;
    }

    fn makeDoublePawnMove(self: *Self, move: Move) void {
        self.movePiece(move.srcIndex, move.dstIndex); // TODO: could make more efficient by including pawn as the piece to move
        self.enPassant = @divExact(move.srcIndex + move.dstIndex, 2);
        self.fiftyMoveCounter = 0;
    }

    fn makeEnPassantMove(self: *Self, move: Move) void {
        var srcXY = bits.indexToXY(move.srcIndex);
        var dstXY = bits.indexToXY(move.dstIndex);

        self.clearXY(srcXY.x, dstXY.y);
        self.movePiece(move.srcIndex, move.dstIndex);
        self.fiftyMoveCounter = 0;
    }

    fn makePromotionQuietMove(self: *Self, move: Move) void {
        self.clearIndex(move.srcIndex); // TODO: could make more efficient by including pawn as the piece to clear
        self.setIndexPiece(move.dstIndex, move.promotionPiece); // TODO: could make more efficient by including pawn as the piece to move
        self.fiftyMoveCounter = 0;
    }

    fn makePromotionCaptureMove(self: *Self, move: Move) void {
        self.clearIndex(move.srcIndex); // TODO: could make more efficient by including pawn as the piece to clear
        self.clearIndex(move.dstIndex);
        self.setIndexPiece(move.dstIndex, move.promotionPiece);
        self.fiftyMoveCounter = 0;
    }

    fn makeCastlingMove(self: *Self, move: Move) void {
        if (move.srcIndex == bits.strToIndex("e1")) {
            self.clearIndex(bits.strToIndex("e1"));
            if (move.dstIndex == bits.strToIndex("h1")) {
                self.clearIndex(bits.strToIndex("h1"));
                self.setIndexPiece(bits.strToIndex("f1"), Piece.WhiteRook);
                self.setIndexPiece(bits.strToIndex("g1"), Piece.WhiteKing);
            } else if (move.dstIndex == bits.strToIndex("a1")) {
                self.clearIndex(bits.strToIndex("a1"));
                self.setIndexPiece(bits.strToIndex("d1"), Piece.WhiteRook);
                self.setIndexPiece(bits.strToIndex("c1"), Piece.WhiteKing);
            } else {
                unreachable;
            }
        } else if (move.srcIndex == bits.strToIndex("e8")) {
            self.clearIndex(bits.strToIndex("e8"));
            if (move.dstIndex == bits.strToIndex("h8")) {
                self.clearIndex(bits.strToIndex("h8"));
                self.setIndexPiece(bits.strToIndex("f8"), Piece.BlackRook);
                self.setIndexPiece(bits.strToIndex("g8"), Piece.BlackKing);
            } else if (move.dstIndex == bits.strToIndex("a8")) {
                self.clearIndex(bits.strToIndex("a8"));
                self.setIndexPiece(bits.strToIndex("d8"), Piece.BlackRook);
                self.setIndexPiece(bits.strToIndex("c8"), Piece.BlackKing);
            } else {
                unreachable;
            }
        } else {
            unreachable;
        }
    }

    pub fn getXYPiece(self: *const Self, x: isize, y: isize) Piece {
        return self.getIndexPiece(bits.xyToIndex(x, y));
    }

    pub fn getIndexPiece(self: *const Self, index: isize) Piece {
        return self.squares[@intCast(usize, index)];
    }

    pub fn setXYPiece(self: *Self, x: isize, y: isize, piece: Piece) void {
        self.setIndexPiece(bits.xyToIndex(x, y), piece);
    }

    pub fn setIndexPiece(self: *Self, index: isize, piece: Piece) void {
        assert(index >= 0);
        assert(index < 64);

        assert(self.getIndexPiece(index).getPieceType() == PieceType.None);
        
        var pieceType = piece.getPieceType();
        assert(pieceType != PieceType.None); // This isn't allowed; must only use clear instead.
        var color = piece.getColor();

        self.occupied.setIndex(index);

        if (color == Color.White)
            self.occupiedWhite.setIndex(index);

        self.occupiedPieces[@enumToInt(pieceType)].setIndex(index);
        self.squares[@intCast(usize, index)] = piece;
    }

    pub fn clearXY(self: *Self, x: isize, y: isize) void {
        self.clearIndex(bits.xyToIndex(x, y));
    }

    pub fn clearIndex(self: *Self, index: isize) void {
        assert(index >= 0);
        assert(index < 64);

        assert(self.getIndexPiece(index).getPieceType() != PieceType.None);

        self.occupied.clearIndex(index);
        self.occupiedWhite.clearIndex(index);
        // TODO: maybe can make this more efficient
        inline for (self.occupiedPieces) |*piece| {
            piece.clearIndex(index);
        }

        self.squares[index] = Piece.None;
    }

    pub fn format(self: Self, comptime fmt: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void
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
            try writer.print("Castling rights: {}\n", .{self.canCastle});
        }
        else 
        {
            @compileError("format type for Piece must be \"short\" for now...");
        }
    }

};