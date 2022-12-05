const std = @import("std");

pub fn dontEliminate(val: bool) void {
    if (val and std.time.timestamp() == 0) {
        std.debug.print("don't eliminate variables\n", .{});
    }
}