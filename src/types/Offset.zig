const std = @import("std");
const df = @import("../damselfly.zig");

const assert = std.debug.assert;

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
                continue;
            }

            if (c == '2')
            {
                assert(p2.set == false);
                p2 = cur;
                p2.set = true;
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

    pub fn allowedFrom(self: Self, index: isize) bool {
        // TODO: look up into allowedFromTable, which is an array of Bitboards, which
        // store the info about whether a source square is allowed to use that offset
        _ = self;
        _ = index;
        unreachable;
    }
};

// TODO: create this
// const allowedFromTable

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