const std = @import("std");
const df = @import("damselfly.zig");
const builtin = @import("builtin");

pub fn assertDebug(cond: bool) void {
    if (comptime builtin.mode == .Debug or df.compileOptions.paranoid == true) {
        std.debug.assert(cond);
    }
}

pub fn assertParanoid(cond: bool) void {
    if (comptime df.compileOptions.paranoid == true) {
        assertDebug(cond);
    }
}