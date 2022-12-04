const std = @import("std");
const df = @import("damselfly");

pub fn main() !void {
    std.debug.print("## xxx ##\n", .{});
    var startingPosition = try df.types.Position.fromFen("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1");
    std.debug.print("{short}\n", .{startingPosition});
    
    var pos2 = try df.types.Position.fromFen("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w - e3 0 1");
    std.debug.print("{short}\n", .{pos2});
    
    var moveList = df.types.MoveList{};
    df.moveGen.generateMoves(&startingPosition, &moveList);
    for (moveList.getItems()) |move| {
        std.debug.print("{} ", .{move});
    }
    std.debug.print("\n\n", .{});

    var pos3 = startingPosition.makeFromMove(moveList.getItems()[3]);
    std.debug.print("{short}\n", .{pos3});
    
    var moveList2 = df.types.MoveList{};
    df.moveGen.generateMoves(&pos3, &moveList2);
    for (moveList2.getItems()) |move| {
        std.debug.print("{} ", .{move});
    }
    std.debug.print("\n\n", .{});

    var kiwipete = try df.types.Position.fromFen("r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - ");
    std.debug.print("{short}\n", .{kiwipete});

    var kiwipeteMoveList = df.types.MoveList{};
    df.moveGen.generateMoves(&kiwipete, &kiwipeteMoveList);
    for (kiwipeteMoveList.getItems()) |move| {
        std.debug.print("{} ", .{move});
    }
    std.debug.print("\n\n", .{});
}
