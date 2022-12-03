const std = @import("std");
const df = @import("damselfly.zig");

const Position = df.types.Position;
const assert = std.debug.assert;

pub fn getLsb(value: u64) isize
{
    return @ctz(value);
}

pub fn removeLsb(value: u64) u64
{
    return value & (value - 1);
}

pub fn popLsb(value: *u64) isize
{
    var ret = getLsb(value.*);
    value.* = removeLsb(value.*);
    return ret;
}

pub fn popCount(value: u64) isize
{
    return @popCount(value);
}

pub fn bitToIndex(value: u64) isize
{
    assert(value & (value-1) == 0);
    return @ctz(value);
}

pub fn indexToBit(index: isize) u64
{
    assert(index >= 0);
    assert(index < 64);
    return @shlExact(@as(u64, 1), @intCast(u6, index));
}

pub const FormattableIndex = struct {
    const Self = @This();

    val: ?isize,

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

pub fn indexToFormattable(index: ?isize) FormattableIndex {
    return FormattableIndex{.val = index};
}

pub fn xyToIndex(x: isize, y: isize) isize {
    assert(x >= 0);
    assert(x < 8);
    assert(y >= 0);
    assert(y < 8);
    return x + (y*8);
}

pub fn strToIndex(str: []const u8) isize {
    assert(str.len == 2);
    assert(str[0] >= 'a' and str[0] <= 'h');
    assert(str[1] >= '1' and str[1] <= '8');

    var file: isize = str[0] - 'a';
    var rank: isize = str[1] - '1';
    return xyToIndex(file, rank);
}

pub fn tryStrToIndex(str: []const u8) Position.Error!isize {
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

pub fn indexToXY(index: isize) IndexToXYRet {
    assert(index >= 0);
    assert(index < 64);
    
    return IndexToXYRet{
        .x = @mod(index, 8),
        .y = @divFloor(index, 8),
    };
}

pub fn parallelBitDeposit(value: u64, mask: u64) u64
{
    // TODO: this would need to be a compile-time option; selecting at runtime would either be very expensive, or incredibly annoying to write. Literally everything would need type parameterization... which could be doable if it was part of the design, but it sounds really annoying.
    // if (Bmi2.X64.IsSupported)
    // {
    // For zig, see: https://github.com/leesongun/othello-nnue/blob/628fee56e63fd05bbae07363336cc305aaaa92cf/game/utils/intrinsic.zig
    //     return Bmi2.X64.ParallelBitDeposit(value, mask);
    // }
    // else
    // {
        return naiveParallelBitDeposit(value, mask);
    // }
}

// TODO: test this
fn naiveParallelBitDeposit(value: u64, mask: u64) u64
{
    var ret: u64 = 0;
    var currentSourceBit: u64 = 1;
    var currentDestBit: u64 = 1;
    while (currentDestBit != 0) : (currentDestBit <<= 1)
    {
        if ((mask & currentDestBit) == 0)
            continue;

        if ((value & currentSourceBit) > 0)
            ret |= currentDestBit;

        currentSourceBit <<= 1;
    }

    return ret;
}

// TODO: test this
fn naiveParallelBitExtract(value: u64, mask: u64) u64
{
    var ret: u64 = 0;
    var currentDestBit: u64 = 1;
    var currentSourceBit: u64 = 1;
    while (currentSourceBit != 0) : (currentSourceBit <<= 1)
    {
        if ((mask & currentSourceBit) == 0)
            continue;

        if ((value & currentSourceBit) > 0)
            ret |= currentDestBit;

        currentDestBit <<= 1;
    }

    return ret;
}

pub const BitIndexIterator = struct {
    const Self = @This();

    value: u64,

    pub fn next(self: *Self) ?isize
    {
        if (self.value == 0)
            return null;
        
        return popLsb(&self.value);
    }
};

pub fn indexIterator(value: u64) BitIndexIterator
{
    return BitIndexIterator{.value = value};
}

pub const BitValueIterator = struct {
    const Self = @This();

    value: u64,

    pub fn next(self: *Self) ?u64
    {
        if (self.value == 0)
            return null;
        
        return @as(u64, 1) << @intCast(u6, popLsb(&self.value));
    }
};

pub fn valueIterator(value: u64) BitValueIterator
{
    return BitValueIterator{.value = value};
}

pub fn tryPopLsb(value: *u64) ?isize
{
    if (value.* == 0)
    {
        return null;
    }

    return popLsb(value);
}

// tests

test "bits.indexIterator" {
    var bb: u64 = 0b00000001_00000001_00000001_00000001_00000001_00000001_00000001_11111111;

    var results = df.StaticArrayList(isize, 99){};
    const expected = [_]isize{0, 1, 2, 3, 4, 5, 6, 7, 8, 16, 24, 32, 40, 48, 56};

    var iter = indexIterator(bb);
    while (iter.next()) |i| {
        results.append(i);
    }

    try std.testing.expectEqualSlices(isize, &expected, results.getItems());
}

test "bits.valueIterator" {
    var bb: u64 = 0b00000001_00000001_00000001_00000001_00000001_00000001_00000001_11111111;

    var results = df.StaticArrayList(u64, 99){};
    const expectedIndexes = [_]isize{0, 1, 2, 3, 4, 5, 6, 7, 8, 16, 24, 32, 40, 48, 56};
    var expectedValues: [expectedIndexes.len]u64 = undefined;
    for (expectedIndexes) |index, i| {
        expectedValues[i] = @as(u64, 1) << @intCast(u6, index);
    }

    var iter = valueIterator(bb);
    while (iter.next()) |val| {
        results.append(val);
    }

    try std.testing.expectEqualSlices(u64, &expectedValues, results.getItems());
}

test "bits.tryPopLsb" {
    var bb: u64 = 0b00000001_00000001_00000001_00000001_00000001_00000001_00000001_11111111;

    var results = df.StaticArrayList(isize, 99){};
    const expected = [_]isize{0, 1, 2, 3, 4, 5, 6, 7, 8, 16, 24, 32, 40, 48, 56};

    while (df.bits.tryPopLsb(&bb)) |i| {
        results.append(i);
    }

    try std.testing.expectEqualSlices(isize, &expected, results.getItems());
    try std.testing.expect(@as(u64, 0) == bb);
}

test "bits.strToIndex" {
    const ix0 = comptime strToIndex("a1");
    const ix7 = comptime strToIndex("h1");
    const ix8 = comptime strToIndex("a2");
    const ix63 = comptime strToIndex("h8");

    try std.testing.expectEqual(0, ix0);
    try std.testing.expectEqual(7, ix7);
    try std.testing.expectEqual(8, ix8);
    try std.testing.expectEqual(63, ix63);
}