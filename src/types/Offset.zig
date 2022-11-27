const std = @import("std");
const df = @import("../damselfly.zig");

const assert = std.debug.assert;
const Bitboard = df.types.Bitboard;

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

    pub fn getAllowedFromBb(self: Self) Bitboard {
        var index = self.val - minAllowedFromOffset.val;
        return allowedFromTable[@intCast(usize, index)];
    }
};

const allowedFromTable: [allowedFromTableSize]Bitboard = CreateAllowedFromTable();
const maxAllowedFromCardinalDistance: isize = 2;
const minAllowedFromOffset = Offset.fromXY(-maxAllowedFromCardinalDistance, -maxAllowedFromCardinalDistance);
const maxAllowedFromOffset = Offset.fromXY(maxAllowedFromCardinalDistance, maxAllowedFromCardinalDistance);
const allowedFromTableSize = maxAllowedFromOffset.val - minAllowedFromOffset.val + 1;

fn CreateAllowedFromTable() [allowedFromTableSize]Bitboard {
    @setEvalBranchQuota(20000);
    var ret: [allowedFromTableSize]Bitboard = [_]Bitboard{Bitboard{.val = 0}} ** allowedFromTableSize;

    var offsY: isize = -maxAllowedFromCardinalDistance;
    while(offsY <= maxAllowedFromCardinalDistance) : (offsY += 1)
    {
        var offsX: isize = -maxAllowedFromCardinalDistance;
        while(offsX <= maxAllowedFromCardinalDistance) : (offsX += 1)
        {
            var curOffset = Offset.fromXY(offsX, offsY);
            var curBitboard = Bitboard{.val = 0};

            var bbY: isize = 0;
            while(bbY < 8) : (bbY += 1)
            {
                var bbX: isize = 0;
                while(bbX < 8) : (bbX += 1)
                {
                    // if can safely jump by offset from current position, then it's safe and we set the bit
                    if (
                        bbX + offsX >= 0 and
                        bbX + offsX < 8 and
                        bbY + offsY >= 0 and
                        bbY + offsY < 8
                    )
                    {
                        curBitboard.setXY(bbX, bbY);
                    }
                }
            }

            var index = curOffset.val - minAllowedFromOffset.val;
            ret[@intCast(usize, index)] = curBitboard;
        }
    }
    
    return ret;
}

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

    const r1ExpectedBb = df.types.Bitboard.fromStr(
        " . . . . . . . . / " ++
        " O O O O O O O O / " ++
        " O O O O O O O O / " ++
        " O O O O O O O O / " ++
        " O O O O O O O O / " ++
        " O O O O O O O O / " ++
        " O O O O O O O O / " ++
        " O O O O O O O O   "
    );

    try std.testing.expectEqual(r1ExpectedBb.val, r1AllowedBb.val);

    const n1 = Offset.fromStr(
        " 1 . / " ++
        " . . / " ++
        " . 2   "
    );

    const n1AllowedBb = n1.getAllowedFromBb();

    const n1ExpectedBb = df.types.Bitboard.fromStr(
        " O O O O O O O . / " ++
        " O O O O O O O . / " ++
        " O O O O O O O . / " ++
        " O O O O O O O . / " ++
        " O O O O O O O . / " ++
        " O O O O O O O . / " ++
        " . . . . . . . . / " ++
        " . . . . . . . .   "
    );

    try std.testing.expectEqual(n1ExpectedBb.val, n1AllowedBb.val);
}