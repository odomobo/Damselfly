const std = @import("std");
const df = @import("damselfly.zig");

const Index = df.types.Index;
const assert = std.debug.assert;

pub fn getLsb(value: u64) Index
{
    // ctz returns a u7, which is only needed if there are 64 zeros. all other values can fit in a u6
    assert(value != 0);
    return @intCast(Index, @ctz(value));
}

pub fn removeLsb(value: u64) u64
{
    assert(value != 0);
    return value & (value - 1);
}

pub fn popLsb(value: *u64) Index
{
    var ret = getLsb(value.*);
    value.* = removeLsb(value.*);
    return ret;
}

pub fn popCount(value: u64) isize
{
    return @popCount(value);
}

pub fn bitToIndex(value: u64) Index
{
    assert(popCount(value) == 1);
    return @intCast(Index, @ctz(value));
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

    pub fn next(self: *Self) ?Index
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
        
        return @as(u64, 1) << popLsb(&self.value);
    }
};

pub fn valueIterator(value: u64) BitValueIterator
{
    return BitValueIterator{.value = value};
}

pub fn tryPopLsb(value: *u64) ?Index
{
    if (value.* == 0)
    {
        return null;
    }

    return popLsb(value);
}

// tests


test "bitboards.indexIterator" {
    var bb: u64 = 0b00000001_00000001_00000001_00000001_00000001_00000001_00000001_11111111;

    var results = df.StaticArrayList(isize, 99){};
    const expected = [_]isize{0, 1, 2, 3, 4, 5, 6, 7, 8, 16, 24, 32, 40, 48, 56};

    var iter = indexIterator(bb);
    while (iter.next()) |i| {
        results.append(i);
    }

    try std.testing.expectEqualSlices(isize, &expected, results.getItems());
}

test "bitboards.valueIterator" {
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

test "bitboards.tryPopLsb" {
    var bb: u64 = 0b00000001_00000001_00000001_00000001_00000001_00000001_00000001_11111111;

    var results = df.StaticArrayList(isize, 99){};
    const expected = [_]isize{0, 1, 2, 3, 4, 5, 6, 7, 8, 16, 24, 32, 40, 48, 56};

    while (df.bitboards.tryPopLsb(&bb)) |i| {
        results.append(i);
    }

    try std.testing.expectEqualSlices(isize, &expected, results.getItems());
    try std.testing.expect(@as(u64, 0) == bb);
}
