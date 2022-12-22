const std = @import("std");
const df = @import("damselfly");

pub const compileOptions = df.types.CompileOptions{
    .configuration = "xxx",
    .paranoid = true,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{ .stack_trace_frames = 20 }){};
    defer _ = gpa.deinit();
    df.init(gpa.allocator()); // important that this is run first
    df.compileOptions.print();

    try makeMovesFromStr();
    //try printZobristKeys();
    //try printBoards();
}

fn makeMovesFromStr() !void {
    var position = try df.types.Position.fromFen(" rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1");
    std.debug.print("{full}\n", .{position});
    position = position.tryMakeMoveFromMoveStr("e2e4").?;
    position = position.tryMakeMoveFromMoveStr("e7e5").?;
    position = position.tryMakeMoveFromMoveStr("g1f3").?;
    position = position.tryMakeMoveFromMoveStr("b8c6").?;
    std.debug.print("{full}\n", .{position});
}

fn printZobristKeys() !void {
    for (df.tables.zobrist.zobristKeys) |key, i| {
        std.debug.print("[{: >3}] : 0x{X:0>16}\n", .{i, key});
    }
}

fn printBoards() !void {
    std.debug.print("## xxx ##\n", .{});
    var startingPosition = try df.types.Position.fromFen(" rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1");
    std.debug.print("{full}\n", .{startingPosition});

    var moveList = df.types.MoveList{};
    df.moveGen.generateMoves(&startingPosition, &moveList);
    for (moveList.getItems()) |move| {
        std.debug.print("{} ", .{move});
    }
    std.debug.print("\n\n", .{});

    if (moveList.getItems().len > 16) {
        var pos3 = startingPosition.makeFromMove(moveList.getItems()[16]);
        std.debug.print("{full}\n", .{pos3});

        var moveList2 = df.types.MoveList{};
        df.moveGen.generateMoves(&pos3, &moveList2);
        for (moveList2.getItems()) |move| {
            std.debug.print("{} ", .{move});
        }
        std.debug.print("\n\n", .{});
    } else {
        std.debug.print("!!! Move list too short to generate move !!!\n\n", .{});
    }

    var pos2 = try df.types.Position.fromFen("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR b - e6 11 21");
    std.debug.print("{full}\n", .{pos2});

    std.debug.print("\n\n", .{});

    var kiwipete = try df.types.Position.fromFen("r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - ");
    std.debug.print("{full}\n", .{kiwipete});

    var kiwipeteMoveList = df.types.MoveList{};
    df.moveGen.generateMoves(&kiwipete, &kiwipeteMoveList);
    for (kiwipeteMoveList.getItems()) |move| {
        std.debug.print("{} ", .{move});
    }
    std.debug.print("\n\n", .{});

    // invalid exposed king
    var errPosition: ?df.types.Position = df.types.Position.fromFen("2b1q3/4N2p/2k2p2/8/4K1Pr/5P2/8/R3n2q w - - 0 1") catch null;
    if (errPosition) |_| {
        std.debug.print("!!!!! invalid exposed king was shown to be a valid position !!!!!\n\n", .{});
    } else {
        std.debug.print("invalid exposed king was shown to be an invalid position\n\n", .{});
    }

    var errPosition2: ?df.types.Position = df.types.Position.fromFen("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR b - e4 11 21") catch null;
    if (errPosition2) |_| {
        std.debug.print("!!!!! invalid en passant was shown to be a valid position !!!!!\n\n", .{});
    } else {
        std.debug.print("invalid en passant was shown to be an invalid position\n\n", .{});
    }

    var exposedKing = try df.types.Position.fromFen("2b1q3/4N3/5p1p/2k5/4K1Pr/5P2/8/R3n2q w - - 0 1");
    std.debug.print("{full}\n", .{exposedKing});

    var exposedKingMoveList = df.types.MoveList{};
    df.moveGen.generateMoves(&exposedKing, &exposedKingMoveList);
    for (exposedKingMoveList.getItems()) |move| {
        std.debug.print("{} ", .{move});
    }
    std.debug.print("\n\n", .{});
}
