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
        assert(x >= 0);
        assert(x < 8);
        assert(y >= 0);
        assert(y < 8);
        var bit = bits.indexToBit(bits.xyToIndex(x, y));
        self.val |= bit;
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