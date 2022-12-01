const std = @import("std");
const df = @import("../damselfly.zig");

pub const Color = enum(u1) {
    const Self = @This();

    White = 0,
    Black = 1,

    pub fn other(self: Color) Color {
        return switch (self)
        {
            Self.White => Self.Black,
            Self.Black => Self.White
        };
    }

    pub fn format(self: Self, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void
    {
        switch (self) {
            Self.White => try writer.print("White", .{}),
            Self.Black => try writer.print("Black", .{}),
        }
    }
};
