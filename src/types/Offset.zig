const std = @import("std");
const df = @import("../damselfly.zig");

const assert = std.debug.assert;
const Bitboard = df.types.Bitboard;
const indexes = df.indexes;
const bitboards = df.bitboards;

const Point = struct {
    x: isize,
    y: isize,
    set: bool,
};

pub const Offset = struct {
    const Self = @This();

    val: isize,

    pub fn fromStr(comptime str: []const u8) Self {
        // note x and y start at the upper left, and work down and right
        var cur = Point{ .x = 0, .y = 0, .set = false };

        var p1 = cur;
        var p2 = cur;

        inline for (str) |c| {
            // gobble whitespace
            if (c == ' ' or c == '\t' or c == '\r' or c == '\n')
                continue;
            
            if (c == '.')
            {
                cur.x += 1;
                continue;
            }

            if (c == '/')
            {
                cur.x = 0;
                cur.y -= 1;
                continue;
            }

            if (c == '1')
            {
                assert(p1.set == false);
                p1 = cur;
                p1.set = true;
                cur.x += 1;
                continue;
            }

            if (c == '2')
            {
                assert(p2.set == false);
                p2 = cur;
                p2.set = true;
                cur.x += 1;
                continue;
            }

            unreachable;
        }

        assert(p1.set == true);
        assert(p2.set == true);

        const p1OffsetFromOrigin = fromXY(p1.x, p1.y);
        const p2OffsetFromOrigin = fromXY(p2.x, p2.y);

        return comptime Self{ .val = p2OffsetFromOrigin.val - p1OffsetFromOrigin.val };
    }

    pub fn fromXY(x: isize, y: isize) Self {
        return Self{ .val = x + (y*8)};
    }

    pub fn getAllowedFromBb(self: Self) Bitboard {
        var index = self.val - df.tables.offsets.minAllowedFromOffset.val;
        return df.tables.offsets.allowedFromTable[@intCast(usize, index)];
    }

    pub fn isAllowedFrom(self: Self, bitboard: Bitboard) bool {
        assert(bitboards.popCount(bitboard) == 1);
        return self.getAllowedFromBb() & bitboard != 0;
    }
};

test "Offset.fromStr" {
    const n1 = Offset.fromStr(
        " 1 . / " ++
        " . . / " ++
        " . 2   "
    );
    try std.testing.expect(n1.val == -15);
}

test "Offset.fromXY" {
    const n1 = Offset.fromXY(1, -2);
    try std.testing.expect(n1.val == -15);
}

test "Offset.getAllowedFromBb" {
    const r1 = Offset.fromStr(
        " 2 / " ++
        " 1   "
    );

    const r1AllowedBb = r1.getAllowedFromBb();

    const r1ExpectedBb = df.bitboards.fromStr(
        " . . . . . . . . / " ++
        " O O O O O O O O / " ++
        " O O O O O O O O / " ++
        " O O O O O O O O / " ++
        " O O O O O O O O / " ++
        " O O O O O O O O / " ++
        " O O O O O O O O / " ++
        " O O O O O O O O   "
    );

    try std.testing.expectEqual(r1ExpectedBb, r1AllowedBb);

    const n1 = Offset.fromStr(
        " 1 . / " ++
        " . . / " ++
        " . 2   "
    );

    const n1AllowedBb = n1.getAllowedFromBb();

    const n1ExpectedBb = df.bitboards.fromStr(
        " O O O O O O O . / " ++
        " O O O O O O O . / " ++
        " O O O O O O O . / " ++
        " O O O O O O O . / " ++
        " O O O O O O O . / " ++
        " O O O O O O O . / " ++
        " . . . . . . . . / " ++
        " . . . . . . . .   "
    );

    try std.testing.expectEqual(n1ExpectedBb, n1AllowedBb);
}