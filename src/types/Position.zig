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
const Movements = df.tables.Movements;

pub const Position = struct {
    const Self = @This();

    pub const Error = error {
        FenInvalid,
    };

    occupied: Bitboard,
    occupiedWhite: Bitboard,
    occupiedPieces: [6]Bitboard,
    inCheck: bool,
    squares: [64]Piece, // TODO: get rid of this? need to benchmark I guess
    parent: ?*const Self,
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
        .inCheck = false,
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

        // if not 1 white king and not 1 black king, then FEN is invalid
        if (bits.popCount(ret.getPieceBb(Color.White, PieceType.King).val) != 1)
            return Error.FenInvalid;

        if (bits.popCount(ret.getPieceBb(Color.Black, PieceType.King).val) != 1)
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
            ret.enPassant = try bits.tryStrToIndex(maybeEpSquare.?);
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

        return ret;
    }

    pub fn makeFromMove(parent: *const Self, move: Move) Self {
        var ret: Self = parent.*;
        
        ret.parent = parent;
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
        } else if (moveType.promotion and moveType.capture) {
            ret.makePromotionCaptureMove(move);
        } else if (moveType.castling and moveType.quiet) {
            ret.makeCastlingMove(move);
        } else {
            unreachable;
        }

        ret.canCastle.updateCastlingFromMove(move);
        // swap side to move after making the move
        ret.sideToMove = parent.sideToMove.other();

        // TODO: zobrist hash

        // TODO: calculate repetition number

        // TODO: update 50 move rule

        ret.calculateInCheck();

        return ret;
    }

    fn movePiece(self: *Self, srcIndex: isize, dstIndex: isize) void {
        var piece = self.squares[@intCast(usize, srcIndex)];
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

        self.clearXY(dstXY.x, srcXY.y);
        self.movePiece(move.srcIndex, move.dstIndex);
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
        if (move.srcIndex == bits.strToIndex("e1")) {
            self.clearIndex(bits.strToIndex("e1"));
            if (move.dstIndex == bits.strToIndex("g1")) {
                self.clearIndex(bits.strToIndex("h1"));
                self.setIndexPiece(bits.strToIndex("f1"), Piece.WhiteRook);
                self.setIndexPiece(bits.strToIndex("g1"), Piece.WhiteKing);
            } else if (move.dstIndex == bits.strToIndex("c1")) {
                self.clearIndex(bits.strToIndex("a1"));
                self.setIndexPiece(bits.strToIndex("d1"), Piece.WhiteRook);
                self.setIndexPiece(bits.strToIndex("c1"), Piece.WhiteKing);
            } else {
                unreachable;
            }
        } else if (move.srcIndex == bits.strToIndex("e8")) {
            self.clearIndex(bits.strToIndex("e8"));
            if (move.dstIndex == bits.strToIndex("g8")) {
                self.clearIndex(bits.strToIndex("h8"));
                self.setIndexPiece(bits.strToIndex("f8"), Piece.BlackRook);
                self.setIndexPiece(bits.strToIndex("g8"), Piece.BlackKing);
            } else if (move.dstIndex == bits.strToIndex("c8")) {
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

    fn calculateInCheck(self: *Self) void {
        var kingVal = self.getPieceBb(self.sideToMove, PieceType.King);
        assert(bits.popCount(kingVal.val) == 1); // this is good to always do, I think? this should never be false, but would be catastrophic if it was
        self.inCheck = self.isSquareAttacked(self.sideToMove, kingVal);
    }

    pub fn isOtherKingInCheck(self: *const Self) bool {
        var kingVal = self.getPieceBb(self.sideToMove.other(), PieceType.King);
        assert(bits.popCount(kingVal.val) == 1); // this is good to always do, I think? this should never be false, but would be catastrophic if it was
        return self.isSquareAttacked(self.sideToMove.other(), kingVal);
    }

    pub fn isSquareAttacked(self: *const Self, color: Color, square: Bitboard) bool {
        assert(bits.popCount(square.val) == 1); // TODO: assertParanoid

        switch (color) {
            inline else => |comptimeColor| {
                // we use the current color for pawn captures, because we're checking in the opposite direction of the pawn's real capture direction
                if (self.isSquareAttackedWithOffsetPieceSlider(comptimeColor, square, Movements.pawnCaptures(comptimeColor), &[_]PieceType{PieceType.Pawn}, false))
                    return true;
            }
        }

        if (self.isSquareAttackedWithOffsetPieceSlider(color, square, Movements.byPieceType(PieceType.Knight), &[_]PieceType{PieceType.Knight}, false))
            return true;
        
        if (self.isSquareAttackedWithOffsetPieceSlider(color, square, Movements.byPieceType(PieceType.Rook), &[_]PieceType{PieceType.Rook, PieceType.Queen}, true))
            return true;

        if (self.isSquareAttackedWithOffsetPieceSlider(color, square, Movements.byPieceType(PieceType.Bishop), &[_]PieceType{PieceType.Bishop, PieceType.Queen}, true))
            return true;

        if (self.isSquareAttackedWithOffsetPieceSlider(color, square, Movements.byPieceType(PieceType.King), &[_]PieceType{PieceType.King}, false))
            return true;

        return false;
    }

    fn isSquareAttackedWithOffsetPieceSlider(self: *const Self, color: Color, square: Bitboard, comptime offsets: []const Offset, comptime pieceTypes: []const PieceType, comptime isSlider: bool) bool {
        assert(bits.popCount(square.val) == 1); // TODO: assertParanoid
        const occupied = self.occupied;
        const otherOccupied = self.getColorBb(color.other());

        for (offsets) |offset| {
            var currentSquare = square;
            while (true) {
                if (!offset.isAllowedFrom(currentSquare))
                    break;
                
                currentSquare = currentSquare.getWithOffset(offset);
                if ((currentSquare.val & otherOccupied.val) != 0)
                {
                    inline for (pieceTypes) |pieceType| {
                        if ((currentSquare.val & self.getPieceBb(color.other(), pieceType).val) != 0) {
                            return true;
                        }
                    }

                    // if it wasn't any of those, then we can't continue in this direction.
                    break;
                }

                // hit our own piece
                if ((currentSquare.val & occupied.val) != 0)
                    break;

                // this shouldn't be a loop if it's not a slider
                if (!isSlider)
                    break;
            }
        }

        return false;
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

        self.squares[@intCast(usize, index)] = Piece.None;
    }

    pub fn getPieceBb(self: *const Self, color: Color, pieceType: PieceType) Bitboard {
        assert(pieceType != PieceType.None);
        
        var colorMask = if (color == Color.White) self.occupiedWhite.val else ~self.occupiedWhite.val;

        return Bitboard{ .val = colorMask & self.occupiedPieces[@enumToInt(pieceType)].val };
    }

    pub fn getColorBb(self: *const Self, color: Color) Bitboard {
        if (color == Color.White) {
            return self.occupiedWhite; // this is always exactly the occupied pieces for white
        } else {
            return Bitboard{ .val = ~self.occupiedWhite.val & self.occupied.val };
        }
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
            try writer.print("En passant square: {}\n", .{bits.indexToFormattable(self.enPassant)});
        }
        else 
        {
            @compileError("format type for Piece must be \"short\" for now...");
        }
    }

};