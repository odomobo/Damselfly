const std = @import("std");
const df = @import("damselfly.zig");

const Position = df.types.Position;
const Index = df.types.Index;
const assert = std.debug.assert;

pub fn indexToBit(index: Index) u64
{
    return @shlExact(@as(u64, 1), index);
}

pub const FormattableIndex = struct {
    const Self = @This();

    val: ?Index,

    pub fn format(self: Self, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void
    {
        if (self.val) |val| {
            var xy = indexToXY(val);
            try writer.print("{c}{c}", .{@intCast(u8, xy.x + 'a'), @intCast(u8, xy.y + '1')});
        } else {
            try writer.print("-", .{});
        }
    }
};

pub fn indexToFormattable(index: ?Index) FormattableIndex {
    return FormattableIndex{.val = index};
}

pub fn xyToIndex(x: isize, y: isize) Index {
    assert(x >= 0);
    assert(x < 8);
    assert(y >= 0);
    assert(y < 8);
    return @intCast(Index, x + (y*8));
}

pub fn strToIndex(str: []const u8) Index {
    assert(str.len == 2);
    assert(str[0] >= 'a' and str[0] <= 'h');
    assert(str[1] >= '1' and str[1] <= '8');

    var file: isize = str[0] - 'a';
    var rank: isize = str[1] - '1';
    return xyToIndex(file, rank);
}

pub fn tryStrToIndex(str: []const u8) Position.Error!Index {
    if (str.len != 2)
        return Position.Error.FenInvalid;

    if (str[0] < 'a' or str[0] > 'h')
        return Position.Error.FenInvalid;

    if (str[1] < '1' or str[1] > '8')
        return Position.Error.FenInvalid;
    
    return strToIndex(str);
}

pub const IndexToXYRet = struct {
    x: isize,
    y: isize,
};

pub fn indexToXY(index: Index) IndexToXYRet {
    return IndexToXYRet{
        .x = @mod(index, 8),
        .y = @divFloor(index, 8),
    };
}

// tests

test "indexes.strToIndex" {
    const ix0 = comptime strToIndex("a1");
    const ix7 = comptime strToIndex("h1");
    const ix8 = comptime strToIndex("a2");
    const ix63 = comptime strToIndex("h8");

    try std.testing.expectEqual(0, ix0);
    try std.testing.expectEqual(7, ix7);
    try std.testing.expectEqual(8, ix8);
    try std.testing.expectEqual(63, ix63);
}