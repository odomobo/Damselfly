const std = @import("std");
const df = @import("damselfly");

const Position = df.types.Position;
const MoveList = df.types.MoveList;

// TODO: set from parameter?
var skipAmount: usize = 1;

pub fn main() !void {
    df.init(); // important that this is run first

    kiwipete();
    initialPos();
    position3();
    position4();
    position4Mirrored();
    position5();
    position6();
}

fn kiwipete() void {
    std.debug.print("\n### kiwipete ###\n", .{});
    const fen = "r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - ";
    perft(fen, 0, 1);
    perft(fen, 1, 48);
    perft(fen, 2, 2039);
    perft(fen, 3, 97862);
    perft(fen, 4, 4085603);
    if (skipAmount < 1)
        perft(fen, 5, 193690690);
}

fn initialPos() void {
    std.debug.print("\n### initial position ###\n", .{});
    const fen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1";
    perft(fen, 0, 1);
    perft(fen, 1, 20);
    perft(fen, 2, 400);
    perft(fen, 3, 8_902);
    perft(fen, 4, 197_281);
    perft(fen, 5, 4_865_609);
    if (skipAmount < 1)
        perft(fen, 6, 119_060_324);
}

fn position3() void {
    std.debug.print("\n### position 3 ###\n", .{});
    const fen = "8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - - ";
    perft(fen, 0, 1);
    perft(fen, 1, 14);
    perft(fen, 2, 191);
    perft(fen, 3, 2812);
    perft(fen, 4, 43238);
    perft(fen, 5, 674624);
    perft(fen, 6, 11030083);
    if (skipAmount < 1)
        perft(fen, 7, 178633661);
}

fn position4() void {
    std.debug.print("\n### position 4 ###\n", .{});
    const fen = "r3k2r/Pppp1ppp/1b3nbN/nP6/BBP1P3/q4N2/Pp1P2PP/R2Q1RK1 w kq - 0 1";
    perft(fen, 0, 1);
    perft(fen, 1, 6);
    perft(fen, 2, 264);
    perft(fen, 3, 9467);
    perft(fen, 4, 422333);
    if (skipAmount < 1)
        perft(fen, 5, 15833292);
}

fn position4Mirrored() void {
    std.debug.print("\n### position 4 mirrored ###\n", .{});
    const fen = "r2q1rk1/pP1p2pp/Q4n2/bbp1p3/Np6/1B3NBn/pPPP1PPP/R3K2R b KQ - 0 1";
    perft(fen, 0, 1);
    perft(fen, 1, 6);
    perft(fen, 2, 264);
    perft(fen, 3, 9467);
    perft(fen, 4, 422333);
    if (skipAmount < 1)
        perft(fen, 5, 15833292);
}

fn position5() void {
    std.debug.print("\n### position 5 ###\n", .{});
    const fen = "rnbq1k1r/pp1Pbppp/2p5/8/2B5/8/PPP1NnPP/RNBQK2R w KQ - 1 8";
    perft(fen, 0, 1);
    perft(fen, 1, 44);
    perft(fen, 2, 1486);
    perft(fen, 3, 62379);
    perft(fen, 4, 2103487);
    if (skipAmount < 1)
        perft(fen, 5, 89941194);
}

fn position6() void {
    std.debug.print("\n### position 6 ###\n", .{});
    const fen = "r4rk1/1pp1qppp/p1np1n2/2b1p1B1/2B1P1b1/P1NP1N2/1PP1QPPP/R4RK1 w - - 0 10";
    perft(fen, 0, 1);
    perft(fen, 1, 46);
    perft(fen, 2, 2079);
    perft(fen, 3, 89890);
    perft(fen, 4, 3894594);
    if (skipAmount < 1)
        perft(fen, 5, 164075551);
}

fn perft(fen: []const u8, depth: usize, expectedNodes: usize) void {
    const position = Position.fromFen(fen) catch unreachable;
    std.debug.print("{s} | depth {} | ", .{fen, depth});

    const foundNodes = innerPerft(&position, depth);
    if (expectedNodes == foundNodes) {
        std.debug.print("Passed; expected {} and found {} nodes\n", .{expectedNodes, foundNodes});
    } else {
        std.debug.print("!!! Failed; expected {} but found {} nodes !!! See position below\n\n", .{expectedNodes, foundNodes});
        std.debug.print("{short}\n", .{position});
    }
}

fn innerPerft(position: *const Position, depth: usize) usize {
    if (depth == 0)
        return 1;
    
    var count: usize = 0;

    var moveList = MoveList{};
    df.moveGen.generateMoves(position, &moveList);

    for (moveList.getItems()) |move| {
        const nextPosition = position.makeFromMove(move);
        count += innerPerft(&nextPosition, depth - 1);
    }

    return count;
}
