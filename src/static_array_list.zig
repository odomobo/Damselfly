const std = @import("std");
const debug = std.debug;
const assert = debug.assert;
const testing = std.testing;
const mem = std.mem;

pub fn StaticArrayList(comptime T: type, comptime Size: usize) type {
    return struct {
        const Self = @This();

        data: [Size]T = undefined,
        len: usize = 0,

        pub fn getItems(self: *Self) []T {
            return self.data[0..self.len];
        }

        pub fn clone(self: *Self) Self {
            return fromSlice(self.getItems());
        }

        pub fn fromSlice(slice: []const T) Self {
            var ret = Self{};
            ret.appendSlice(slice);
            return ret;
        }

        pub fn insert(self: *Self, n: usize, item: T) void {
            self.len += 1;
            assert(self.len <= Size);

            mem.copyBackwards(T, self.data[n + 1 .. self.len], self.data[n .. self.len - 1]);
            self.data[n] = item;
        }

        pub fn insertSlice(self: *Self, i: usize, items: []const T) void {
            self.len += items.len;
            assert(self.len <= Size);

            mem.copyBackwards(T, self.data[i + items.len .. self.len], self.data[i .. self.len - items.len]);
            mem.copy(T, self.data[i .. i + items.len], items);
        }

        pub fn replaceRange(self: *Self, start: usize, len: usize, new_items: []const T) void {
            assert(start + new_items.len <= self.len);
            assert(start + len <= Size);

            const after_range = start + len;
            const range = self.data[start..after_range];

            if (range.len == new_items.len)
                mem.copy(T, range, new_items)
            else if (range.len < new_items.len) {
                const first = new_items[0..range.len];
                const rest = new_items[range.len..];

                mem.copy(T, range, first);
                self.insertSlice(after_range, rest);
            } else {
                mem.copy(T, range, new_items);
                const after_subrange = start + new_items.len;

                for (self.data[after_range..self.len]) |item, i| {
                    self.data[after_subrange..][i] = item;
                }

                self.len -= len - new_items.len;
            }
        }

        pub fn append(self: *Self, item: T) void {
            const new_item_ptr = self.addOne();
            new_item_ptr.* = item;
        }

        pub fn orderedRemove(self: *Self, i: usize) T {
            assert(i < self.len);
            const newlen = self.len - 1;
            if (newlen == i) return self.pop();

            const old_item = self.data[i];
            for (self.data[i..newlen]) |*b, j| b.* = self.data[i + 1 + j];
            self.data[newlen] = undefined;
            self.len = newlen;
            return old_item;
        }

        pub fn swapRemove(self: *Self, i: usize) T {
            assert(i < self.len);
            if (self.len - 1 == i) return self.pop();

            const old_item = self.data[i];
            self.data[i] = self.pop();
            return old_item;
        }

        pub fn appendSlice(self: *Self, items: []const T) void {
            const old_len = self.len;
            const new_len = old_len + items.len;
            assert(new_len <= Size);
            self.len = new_len;
            mem.copy(T, self.data[old_len..], items);
        }

        pub fn appendNTimes(self: *Self, value: T, n: usize) void {
            const new_len = self.len + n;
            assert(new_len <= Size);
            mem.set(T, self.data[self.len..new_len], value);
            self.len = new_len;
        }

        pub fn resize(self: *Self, new_len: usize) void {
            assert(new_len <= Size);
            self.len = new_len;
        }

        pub fn addOne(self: *Self) *T {
            assert(self.len < Size);

            self.len += 1;
            return &self.data[self.len - 1];
        }

        pub fn addManyAsArray(self: *Self, comptime n: usize) *[n]T {
            assert(self.len + n <= Size);
            const prev_len = self.len;
            self.len += n;
            return self.data[prev_len..][0..n];
        }

        pub fn pop(self: *Self) T {
            assert(self.len > 0);
            const val = self.data[self.len - 1];
            self.len -= 1;
            return val;
        }

        pub fn popOrNull(self: *Self) ?T {
            if (self.len == 0) return null;
            return self.pop();
        }
    };
}

test "StaticArrayList.init" {
    var list = StaticArrayList(i32, 99){};

    try testing.expect(list.len == 0);
}


test "StaticArrayList.clone" {
    var array = StaticArrayList(i32, 99){};
    array.append(-1);
    array.append(3);
    array.append(5);

    var cloned = array.clone();

    try testing.expectEqualSlices(i32, array.getItems(), cloned.getItems());

    try testing.expectEqual(@as(i32, -1), cloned.getItems()[0]);
    try testing.expectEqual(@as(i32, 3), cloned.getItems()[1]);
    try testing.expectEqual(@as(i32, 5), cloned.getItems()[2]);
}

test "StaticArrayList.basic" {
    var list = StaticArrayList(i32, 99){};

    {
        var i: usize = 0;
        while (i < 10) : (i += 1) {
            list.append(@intCast(i32, i + 1));
        }
    }

    {
        var i: usize = 0;
        while (i < 10) : (i += 1) {
            try testing.expect(list.getItems()[i] == @intCast(i32, i + 1));
        }
    }

    for (list.getItems()) |v, i| {
        try testing.expect(v == @intCast(i32, i + 1));
    }

    try testing.expect(list.pop() == 10);
    try testing.expect(list.getItems().len == 9);

    list.appendSlice(&[_]i32{ 1, 2, 3 });
    try testing.expect(list.getItems().len == 12);
    try testing.expect(list.pop() == 3);
    try testing.expect(list.pop() == 2);
    try testing.expect(list.pop() == 1);
    try testing.expect(list.getItems().len == 9);

    //var unaligned: [3]i32 align(1) = [_]i32{ 4, 5, 6 };
    //list.appendUnalignedSlice(&unaligned);
    var unaligned: [3]i32 = [_]i32{ 4, 5, 6 };
    list.appendSlice(&unaligned);
    try testing.expect(list.getItems().len == 12);
    try testing.expect(list.pop() == 6);
    try testing.expect(list.pop() == 5);
    try testing.expect(list.pop() == 4);
    try testing.expect(list.getItems().len == 9);

    list.appendSlice(&[_]i32{});
    try testing.expect(list.getItems().len == 9);

    // can only set on indices < self.getItems().len
    list.getItems()[7] = 33;
    list.getItems()[8] = 42;

    try testing.expect(list.pop() == 42);
    try testing.expect(list.pop() == 33);
}

test "StaticArrayList.appendNTimes" {
    var list = StaticArrayList(i32, 99){};

    list.appendNTimes(2, 10);
    try testing.expectEqual(@as(usize, 10), list.getItems().len);
    for (list.getItems()) |element| {
        try testing.expectEqual(@as(i32, 2), element);
    }
}


test "StaticArrayList.orderedRemove" {
    var list = StaticArrayList(i32, 99){};

    list.append(1);
    list.append(2);
    list.append(3);
    list.append(4);
    list.append(5);
    list.append(6);
    list.append(7);

    //remove from middle
    try testing.expectEqual(@as(i32, 4), list.orderedRemove(3));
    try testing.expectEqual(@as(i32, 5), list.getItems()[3]);
    try testing.expectEqual(@as(usize, 6), list.getItems().len);

    //remove from end
    try testing.expectEqual(@as(i32, 7), list.orderedRemove(5));
    try testing.expectEqual(@as(usize, 5), list.getItems().len);

    //remove from front
    try testing.expectEqual(@as(i32, 1), list.orderedRemove(0));
    try testing.expectEqual(@as(i32, 2), list.getItems()[0]);
    try testing.expectEqual(@as(usize, 4), list.getItems().len);
}

test "StaticArrayList.swapRemove" {
    var list = StaticArrayList(i32, 99){};

    list.append(1);
    list.append(2);
    list.append(3);
    list.append(4);
    list.append(5);
    list.append(6);
    list.append(7);

    //remove from middle
    try testing.expect(list.swapRemove(3) == 4);
    try testing.expect(list.getItems()[3] == 7);
    try testing.expect(list.getItems().len == 6);

    //remove from end
    try testing.expect(list.swapRemove(5) == 6);
    try testing.expect(list.getItems().len == 5);

    //remove from front
    try testing.expect(list.swapRemove(0) == 1);
    try testing.expect(list.getItems()[0] == 5);
    try testing.expect(list.getItems().len == 4);
}

test "StaticArrayList.insert" {
    var list = StaticArrayList(i32, 99){};

    list.append(1);
    list.append(2);
    list.append(3);
    list.insert(0, 5);
    try testing.expect(list.getItems()[0] == 5);
    try testing.expect(list.getItems()[1] == 1);
    try testing.expect(list.getItems()[2] == 2);
    try testing.expect(list.getItems()[3] == 3);
}

test "StaticArrayList.insertSlice" {
    var list = StaticArrayList(i32, 99){};

    list.append(1);
    list.append(2);
    list.append(3);
    list.append(4);
    list.insertSlice(1, &[_]i32{ 9, 8 });
    try testing.expect(list.getItems()[0] == 1);
    try testing.expect(list.getItems()[1] == 9);
    try testing.expect(list.getItems()[2] == 8);
    try testing.expect(list.getItems()[3] == 2);
    try testing.expect(list.getItems()[4] == 3);
    try testing.expect(list.getItems()[5] == 4);

    const items = [_]i32{1};
    list.insertSlice(0, items[0..0]);
    try testing.expect(list.getItems().len == 6);
    try testing.expect(list.getItems()[0] == 1);
}

test "StaticArrayList.replaceRange" {
    const init = [_]i32{ 1, 2, 3, 4, 5 };
    const new = [_]i32{ 0, 0, 0 };

    const result_zero = [_]i32{ 1, 0, 0, 0, 2, 3, 4, 5 };
    const result_eq = [_]i32{ 1, 0, 0, 0, 5 };
    const result_le = [_]i32{ 1, 0, 0, 0, 4, 5 };
    const result_gt = [_]i32{ 1, 0, 0, 0 };

    {
        var list_zero = StaticArrayList(i32, 99){};
        var list_eq = StaticArrayList(i32, 99){};
        var list_lt = StaticArrayList(i32, 99){};
        var list_gt = StaticArrayList(i32, 99){};

        list_zero.appendSlice(&init);
        list_eq.appendSlice(&init);
        list_lt.appendSlice(&init);
        list_gt.appendSlice(&init);

        list_zero.replaceRange(1, 0, &new);
        list_eq.replaceRange(1, 3, &new);
        list_lt.replaceRange(1, 2, &new);

        // after_range > new_items.len in function body
        try testing.expect(1 + 4 > new.len);
        list_gt.replaceRange(1, 4, &new);

        try testing.expectEqualSlices(i32, list_zero.getItems(), &result_zero);
        try testing.expectEqualSlices(i32, list_eq.getItems(), &result_eq);
        try testing.expectEqualSlices(i32, list_lt.getItems(), &result_le);
        try testing.expectEqualSlices(i32, list_gt.getItems(), &result_gt);
    }
}


test "StaticArrayList.addManyAsArray" {
    var list = StaticArrayList(u8, 99){};

    list.addManyAsArray(4).* = "aoeu".*;
    list.addManyAsArray(4).* = "asdf".*;

    try testing.expectEqualSlices(u8, list.getItems(), "aoeuasdf");
}

// The below causes tests to crash for some reason
//test "std.ArrayList(u0)" {
//    var list = StaticArrayList(u0, 99){};
//
//    list.append(0);
//    list.append(0);
//    list.append(0);
//    try testing.expectEqual(list.getItems().len, 3);
//
//    var count: usize = 0;
//    for (list.getItems()) |x| {
//        try testing.expectEqual(x, 0);
//        count += 1;
//    }
//    try testing.expectEqual(count, 3);
//}