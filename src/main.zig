const std = @import("std");
const df = @import("damselfly.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{ .stack_trace_frames = 20 }){};
    defer _ = gpa.deinit();
    df.init(gpa.allocator()); // important that this is run first

    std.debug.print("Damselfly is arriving\n", .{});
}
