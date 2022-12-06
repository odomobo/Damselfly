const std = @import("std");
const df = @import("damselfly.zig");

const Index = df.types.Index;
const indexes = df.indexes;
const Bitboard = df.types.Bitboard;
const Offset = df.types.Offset;
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

pub const BitboardPieceIterator = struct {
    const Self = @This();

    val: u64,

    pub fn next(self: *Self) ?Bitboard
    {
        if (self.val == 0)
            return null;
        
        return Bitboard{ .val = @as(u64, 1) << @intCast(u6, popLsb(&self.val)) };
    }
};

pub fn getSquareIterator(self: Bitboard) BitboardPieceIterator { // TODO: can the return type be made more anonymous?
    return BitboardPieceIterator{ .val = self.val };
}

pub fn tryPopLsb(value: *u64) ?Index
{
    if (value.* == 0)
    {
        return null;
    }

    return popLsb(value);
}

const Point = struct {
    x: isize,
    y: isize,
};

pub fn fromStr(comptime str: []const u8) Bitboard {
    var ret = Bitboard{ .val = 0 };

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
            setXY(&ret, next.x, next.y);
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

pub fn setXY(self: *Bitboard, x: isize, y: isize) void {
    setIndex(self, indexes.xyToIndex(x, y));
}

pub fn setIndex(self: *Bitboard, index: Index) void {
    var bit = indexes.indexToBit(index);
    self.val |= bit;
}

pub fn clearXY(self: *Bitboard, x: isize, y: isize) void {
    clearIndex(self, indexes.xyToIndex(x, y));
}

pub fn clearIndex(self: *Bitboard, index: Index) void {
    var bit = indexes.indexToBit(index);
    self.val &= ~bit;
}

pub fn hasBitXY(self: Bitboard, x: isize, y: isize) bool {
    return hasBitIndex(self, indexes.xyToIndex(x, y));
}

pub fn hasBitIndex(self: Bitboard, index: Index) bool {
    var bit = indexes.indexToBit(index);
    return (self.val & bit) != 0;
}

pub fn toIndex(self: Bitboard) Index {
    assert(popCount(self.val) == 1);
    return bitToIndex(self.val);
}

pub fn getWithOffset(self: Bitboard, offset: Offset) Bitboard {
    if (offset.val >= 0) {
        return Bitboard{ .val = @shlExact(self.val, @intCast(u6, offset.val))};
    } else {
        return Bitboard{ .val = @shrExact(self.val, @intCast(u6, -offset.val))};
    }
}

pub const FormattableBitboard = struct {
    const Self = @This();

    bitboard: ?Bitboard,

    pub fn format(self: Self, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void
    {
        var y: isize = 7;
        while(y >= 0) : (y -= 1)
        {
            var x: isize = 0;
            while(x < 8) : (x += 1)
            {
                if (hasBitXY(self.bitboard, x, y)) {
                    try writer.print("O ", .{});
                } else {
                    try writer.print(". ", .{});
                }
            }
            try writer.print("\n", .{});
        }
    }
};

pub fn toFormattable(bitboard: ?Bitboard) FormattableBitboard {
    return FormattableBitboard{.bitboard = bitboard};
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

test "bitboards.getSquareIterator" {
    var bb: u64 = 0b00000001_00000001_00000001_00000001_00000001_00000001_00000001_11111111;

    var results = df.StaticArrayList(u64, 99){};
    const expectedIndexes = [_]isize{0, 1, 2, 3, 4, 5, 6, 7, 8, 16, 24, 32, 40, 48, 56};
    var expectedValues: [expectedIndexes.len]u64 = undefined;
    for (expectedIndexes) |index, i| {
        expectedValues[i] = @as(u64, 1) << @intCast(u6, index);
    }

    var iter = getSquareIterator(bb);
    while (iter.next()) |val| {
        results.append(val);
    }

    try std.testing.expectEqualSlices(u64, &expectedValues, results.getItems());
}

test "bitboards.tryPopLsb" {
    var bb: u64 = 0b00000001_00000001_00000001_00000001_00000001_00000001_00000001_11111111;

    var results = df.StaticArrayList(isize, 99){};
    const expected = [_]isize{0, 1, 2, 3, 4, 5, 6, 7, 8, 16, 24, 32, 40, 48, 56};

    while (tryPopLsb(&bb)) |i| {
        results.append(i);
    }

    try std.testing.expectEqualSlices(isize, &expected, results.getItems());
    try std.testing.expect(@as(u64, 0) == bb);
}


test "bitboards.fromStr" {
    var u64_1: u64 = 0b00000001_00000001_00000001_00000001_00000001_00000001_00000001_11111111;

    const bitboard_1 = fromStr(
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

    const bitboard_2 = fromStr(
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