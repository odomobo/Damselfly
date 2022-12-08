const std = @import("std");
const df = @import("../damselfly.zig");

pub const CompileOptions = struct {
    const Self = @This();

    configuration: []const u8 = "Default",
    paranoid: bool = false,

    pub fn print(self: *const Self) void {
        var options = std.json.stringifyAlloc(df.allocator, self, .{ .whitespace = std.json.StringifyOptions.Whitespace{} }) catch @panic("out of memory");
        defer df.allocator.free(options);
        std.debug.print("Compile-time configuration options:\n{s}\n", .{options});
    }
};