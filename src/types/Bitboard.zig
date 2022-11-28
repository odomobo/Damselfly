const std = @import("std");
const df = @import("../damselfly.zig");

const bits = df.bits;
const assert = std.debug.assert;

const Point = struct {
    x: isize,
    y: isize,
};

pub const Bitboard = struct {
    const Self = @This();

    pub const empty = Self{.val = 0};

    val: u64,

    pub fn fromStr(comptime str: []const u8) Self {
        var ret = Self{ .val = 0 };

        var next = Point{ .x = 0, .y = 7 };
        
        inline for (str) |c| {
            // gobble whitespace
            if (c == ' ' or c == '\t' or c == '\r' or c == '\n')
                continue;

            if (c == '.')
            {
                assert(next.x < 8);
                assert(next.y >= 0);
                // don't add a 0 to the bitboard
                next.x += 1;
                continue;
            }

            if (c == 'O')
            {
                assert(next.x < 8);
                assert(next.y >= 0);
                ret.setXY(next.x, next.y);
                next.x += 1;
                continue;
            }

            if (c == '/')
            {
                assert(next.x == 8);
                assert(next.y > 0);
                next.x = 0;
                next.y -= 1;
                continue;
            }

            unreachable;
        }

        assert(next.x == 8); // after reading the last square, it still iterates to the next
        assert(next.y == 0);

        return comptime ret;
    }

    pub fn setXY(self: *Self, x: isize, y: isize) void {
        self.setIndex(bits.xyToIndex(x, y));
    }

    pub fn setIndex(self: *Self, index: isize) void {
        var bit = bits.indexToBit(index);
        self.val |= bit;
    }

    pub fn clearXY(self: *Self, x: isize, y: isize) void {
        self.clearIndex(bits.xyToIndex(x, y));
    }

    pub fn clearIndex(self: *Self, index: isize) void {
        var bit = bits.indexToBit(index);
        self.val &= ~bit;
    }

    pub fn hasBitXY(self: Self, x: isize, y: isize) bool {
        return self.hasBitIndex(bits.xyToIndex(x, y));
    }

    pub fn hasBitIndex(self: Self, index: isize) bool {
        var bit = bits.indexToBit(index);
        return (self.val & bit) != 0;
    }

    pub fn format(self: Self, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void
    {
        var y: isize = 7;
        while(y >= 0) : (y -= 1)
        {
            var x: isize = 0;
            while(x < 8) : (x += 1)
            {
                if (self.hasBitXY(x, y)) {
                    try writer.print("O ", .{});
                } else {
                    try writer.print(". ", .{});
                }
            }
            try writer.print("\n", .{});
        }
    }
};

test "Bitboard.fromStr" {
    var u64_1: u64 = 0b00000001_00000001_00000001_00000001_00000001_00000001_00000001_11111111;

    const bitboard_1 = Bitboard.fromStr(
        " O . . . . . . . / " ++
        " O . . . . . . . / " ++
        " O . . . . . . . / " ++
        " O . . . . . . . / " ++
        " O . . . . . . . / " ++
        " O . . . . . . . / " ++
        " O . . . . . . . / " ++
        " O O O O O O O O   "
    );
    
    try std.testing.expect(u64_1 == bitboard_1.val);

    var u64_2: u64 = 0b00000000_00000000_00000000_00010000_00010000_00011110_00000010_00000010;

    const bitboard_2 = Bitboard.fromStr(
        " . . . . . . . . / " ++
        " . . . . . . . . / " ++
        " . . . . . . . . / " ++
        " . . . . O . . . / " ++
        " . . . . O . . . / " ++
        " . O O O O . . . / " ++
        " . O . . . . . . / " ++
        " . O . . . . . .   "
    );
    
    try std.testing.expect(u64_2 == bitboard_2.val);
}