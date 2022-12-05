const std = @import("std");

// TODO: remove; this probably doesn't do anything
pub fn dontEliminate(val: bool) void {
    if (val and std.time.timestamp() == 0) {
        std.debug.print("don't eliminate variables\n", .{});
    }
}

// TODO: remove; this probably doesn't do anything
pub fn dontEliminatePtr(ptr: *const anyopaque) void {
    if (ptr == @intToPtr(*const anyopaque, 10) and std.time.timestamp() == 0) {
        std.debug.print("don't eliminate variables\n", .{});
    }
}