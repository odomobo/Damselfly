const std = @import("std");
const df = @import("damselfly.zig");

pub fn main() !void {
    df.init(); // important that this is run first

    std.debug.print("Damselfly is arriving\n", .{});
}
