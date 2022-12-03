const std = @import("std");
const df = @import("damselfly");

pub fn main() !void {
    std.debug.print("## xxx ##\n", .{});
    var startingPosition = try df.types.Position.fromFen("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1");
    std.debug.print("{short}\n", .{startingPosition});

    var pos2 = try df.types.Position.fromFen("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w - e3 0 1");
    std.debug.print("{short}\n", .{pos2});
}
