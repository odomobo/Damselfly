const std = @import("std");
const df = @import("../damselfly.zig");

const assert = std.debug.assert;

const ZobristHash = df.types.ZobristHash;
const Color = df.types.Color;
const PieceType = df.types.PieceType;
const Index = df.types.Index;
const Position = df.types.Position;

const indexes = df.indexes;

pub fn init() void {
    zobristKeysInner = generateZobristKeys();
}

pub fn getZobristHashForPosition(position: *const Position) ZobristHash {
    var ret: ZobristHash = 0;

    for ([_]Color{.White, .Black}) |color| {
        for ([_]PieceType{.Pawn, .Knight, .Bishop, .Rook, .Queen, .King}) |pieceType| {
            var iter = df.bitboards.indexIterator(position.getPieceBb(color, pieceType));
            while (iter.next()) |index| {
                ret ^= getZobristKeyColorPieceTypeIndex(color, pieceType, index);
            }
        }
    }

    ret ^= getZobristKeyEnPassant(position.enPassant);

    if (position.canCastle.whiteKingside)
        ret ^= getZobristKeyCastlingWhiteKingside();

    if (position.canCastle.whiteQueenside)
        ret ^= getZobristKeyCastlingWhiteQueenside();

    if (position.canCastle.blackKingside)
        ret ^= getZobristKeyCastlingBlackKingside();

    if (position.canCastle.blackQueenside)
        ret ^= getZobristKeyCastlingBlackQueenside();
    
    if (position.sideToMove == .Black)
        ret ^= getZobristKeyBlackToMove();
    
    return ret;
}

pub fn getZobristKeyColorPieceTypeIndex(color: Color, pieceType: PieceType, index: Index) ZobristHash {
    var offset: usize = pieceStartIndex;
    offset += @enumToInt(color) * @as(usize, colorPieceBlockSize);
    offset += @enumToInt(pieceType) * @as(usize, singlePieceBlockSize);
    offset += index;

    return zobristKeys[offset];
}

pub fn getZobristKeyEnPassant(enPassantIndex: ?Index) ZobristHash {
    if (enPassantIndex) |index| {
        assert( 
            ( index >= indexes.strToIndex("a3") and index <= indexes.strToIndex("h3") ) or
            ( index >= indexes.strToIndex("a6") and index <= indexes.strToIndex("h6") )
        );

        var offset: usize = enPassantStartIndex;

        // if white side
        if (index <= indexes.strToIndex("h3"))
        {
            offset += index - indexes.strToIndex("a3");
        } else { // if black side
            offset += enPassantColorBlockSize;
            offset += index - indexes.strToIndex("a6");
        }

        return zobristKeys[offset];
    } else {
        return 0;
    }
}

pub fn getZobristKeyCastlingWhiteKingside() ZobristHash {
    return zobristKeys[castlingStartIndex + 0];
}

pub fn getZobristKeyCastlingWhiteQueenside() ZobristHash {
    return zobristKeys[castlingStartIndex + 1];
}

pub fn getZobristKeyCastlingBlackKingside() ZobristHash {
    return zobristKeys[castlingStartIndex + 2];
}

pub fn getZobristKeyCastlingBlackQueenside() ZobristHash {
    return zobristKeys[castlingStartIndex + 3];
}

pub fn getZobristKeyBlackToMove() ZobristHash {
    return zobristKeys[blackToMoveStartIndex];
}

// Zobrist keys are ordered as follows:
// [0..63] First, all white pawn keys, from bitboard index 0 through 63
// [64..127] Next, all white knight keys, from bitboard index 0 through 63
// [128..383] Next all white bishop, rook, queen, king keys, each from bitboard index 0 through 63
// [384..767] Next all black pawn, knight, bishop, rook, queen, king keys, each from bitboard index 0 through 63
// [768..783] Next, all en passant squares, in order of a3 to h3, followed by a6 thorugh h6
// [784..787] Next, all castling keys: white kingside, white queenside, black kingside, black queenside in that order
// [788] Finally, the black-to-move key
pub var zobristKeysInner = [_]ZobristHash{0} ** zobristKeysSize;
// TODO: get rid of this once zig compiler issue is fixed
pub const zobristKeys = &zobristKeysInner;

const pieceStartIndex = 0;
const singlePieceBlockSize = 64;
const colorPieceBlockSize = singlePieceBlockSize*6;
const allPieceBlockSize = colorPieceBlockSize*2;
const enPassantStartIndex = pieceStartIndex + allPieceBlockSize;
const enPassantColorBlockSize = 8;
const enPassantAllBlockSize = enPassantColorBlockSize * 2;
const castlingStartIndex = enPassantStartIndex + enPassantAllBlockSize;
const castlingBlockSize = 4;
const blackToMoveStartIndex = castlingStartIndex + castlingBlockSize;
const blackToMoveSize = 1;

const zobristKeysSize = blackToMoveStartIndex + blackToMoveSize;
fn generateZobristKeys() [zobristKeysSize]ZobristHash {
    var ret: [zobristKeysSize]ZobristHash = undefined;
    var rng = std.rand.DefaultPrng.init(0);
    
    var i: usize = 0;
    while(i < ret.len) : (i += 1) {
        ret[i] = rng.random().int(ZobristHash);
    }

    return ret;
}

test "getZobristHashForPosition() uniqueness" {
    // just verify that duplicates get removed
    {
        var duplicates = std.hash_map.AutoHashMap(ZobristHash, void).init(std.testing.allocator);
        defer duplicates.deinit();

        try duplicates.put(10, {});
        try duplicates.put(10, {});
        try std.testing.expect(duplicates.count() == 1);
    }

    // verify that every key is unique
    {
        var hashKeys = std.hash_map.AutoHashMap(ZobristHash, void).init(std.testing.allocator);
        defer hashKeys.deinit();

        var addedCount: usize = 0;

        for ([_]Color{.White, .Black}) |color| {
            for ([_]PieceType{.Pawn, .Knight, .Bishop, .Rook, .Queen, .King}) |pieceType| {
                var i: usize = 0;
                while (i < 64) : (i += 1) {
                    const index = @intCast(Index, i);
                    try hashKeys.put(getZobristKeyColorPieceTypeIndex(color, pieceType, index), {});
                    addedCount += 1;
                }
            }
        }

        var index = indexes.strToIndex("a3");
        while (index <= indexes.strToIndex("h3")) : (index += 1) {
            try hashKeys.put(getZobristKeyEnPassant(index), {});
            addedCount += 1;
        }

        index = indexes.strToIndex("a6");
        while (index <= indexes.strToIndex("h6")) : (index += 1) {
            try hashKeys.put(getZobristKeyEnPassant(index), {});
            addedCount += 1;
        }

        try hashKeys.put(getZobristKeyCastlingWhiteKingside(), {});
        addedCount += 1;
        try hashKeys.put(getZobristKeyCastlingWhiteQueenside(), {});
        addedCount += 1;
        try hashKeys.put(getZobristKeyCastlingBlackKingside(), {});
        addedCount += 1;
        try hashKeys.put(getZobristKeyCastlingBlackQueenside(), {});
        addedCount += 1;

        try hashKeys.put(getZobristKeyBlackToMove(), {});
        addedCount += 1;

        // this proves that all keys returned from the various methods are all unique
        try std.testing.expect(hashKeys.count() == zobristKeys.len);
        try std.testing.expect(hashKeys.count() == addedCount);
    }
}

test "getZobristHashForPosition() differentiates different positions" {
    var kiwipete = try Position.fromFen("r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - ");

    var withMissingA1Rook = kiwipete;
    withMissingA1Rook.clearIndex(indexes.strToIndex("a1"));
    withMissingA1Rook.zobristHash = getZobristHashForPosition(&withMissingA1Rook);

    try std.testing.expect(kiwipete.zobristHash != withMissingA1Rook.zobristHash);

    var withEnPassant = kiwipete;
    withEnPassant.enPassant = indexes.strToIndex("e3");
    withEnPassant.zobristHash = getZobristHashForPosition(&withEnPassant);

    try std.testing.expect(kiwipete.zobristHash != withEnPassant.zobristHash);

    var withMissingCastlingRights = kiwipete;
    withMissingCastlingRights.canCastle.whiteKingside = false;
    withMissingCastlingRights.zobristHash = getZobristHashForPosition(&withMissingCastlingRights);

    try std.testing.expect(kiwipete.zobristHash != withMissingCastlingRights.zobristHash);

    var withBlackToMove = kiwipete;
    withBlackToMove.sideToMove = .Black;
    withBlackToMove.zobristHash = getZobristHashForPosition(&withBlackToMove);

    try std.testing.expect(kiwipete.zobristHash != withBlackToMove.zobristHash);
}