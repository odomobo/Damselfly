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

    //try printZobristKeys();
    try printBoards();
}

fn printZobristKeys() !void {
    for (df.tables.zobrist.zobristKeys) |key, i| {
        std.debug.print("[{: >3}] : 0x{X:0>16}\n", .{i, key});
    }
}

fn printBoards() !void {
    std.debug.print("## xxx ##\n", .{});
    var startingPosition = try df.types.Position.fromFen("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1");
    std.debug.print("{short}\n", .{startingPosition});

    var moveList = df.types.MoveList{};
    df.moveGen.generateMoves(&startingPosition, &moveList);
    for (moveList.getItems()) |move| {
        std.debug.print("{} ", .{move});
    }
    std.debug.print("\n\n", .{});

    if (moveList.getItems().len > 3) {
        var pos3 = startingPosition.makeFromMove(moveList.getItems()[3]);
        std.debug.print("{short}\n", .{pos3});

        var moveList2 = df.types.MoveList{};
        df.moveGen.generateMoves(&pos3, &moveList2);
        for (moveList2.getItems()) |move| {
            std.debug.print("{} ", .{move});
        }
        std.debug.print("\n\n", .{});
    } else {
        std.debug.print("!!! Move list too short to generate move !!!\n\n", .{});
    }

    var pos2 = try df.types.Position.fromFen("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w - e3 0 1");
    std.debug.print("{short}\n", .{pos2});

    std.debug.print("\n\n", .{});

    var kiwipete = try df.types.Position.fromFen("r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - ");
    std.debug.print("{short}\n", .{kiwipete});

    var kiwipeteMoveList = df.types.MoveList{};
    df.moveGen.generateMoves(&kiwipete, &kiwipeteMoveList);
    for (kiwipeteMoveList.getItems()) |move| {
        std.debug.print("{} ", .{move});
    }
    std.debug.print("\n\n", .{});

    // invalid exposed king
    //if (df.types.Position.fromFen("2b1q3/4N2p/2k2p2/8/4K1Pr/5P2/8/R3n2q w - - 0 1") == .FenInvalid) {
    //    std.debug.print("invalid exposed king was shown to be an invalid position\n\n", .{});
    //} else {
    //    std.debug.print("!!!!! invalid exposed king was shown to be a valid position !!!!!\n\n", .{});
    //}

    var exposedKing = try df.types.Position.fromFen("2b1q3/4N3/5p1p/2k5/4K1Pr/5P2/8/R3n2q w - - 0 1");
    std.debug.print("{short}\n", .{exposedKing});

    var exposedKingMoveList = df.types.MoveList{};
    df.moveGen.generateMoves(&exposedKing, &exposedKingMoveList);
    for (exposedKingMoveList.getItems()) |move| {
        std.debug.print("{} ", .{move});
    }
    std.debug.print("\n\n", .{});
}
