const std = @import("std");
const builtin = @import("builtin");

pub fn assertDebug(cond: bool) void {
    if (comptime builtin.mode == .Debug) {
        std.debug.assert(cond);
    }
}