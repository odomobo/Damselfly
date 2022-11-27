const std = @import("std");
const df = @import("damselfly.zig");

// allows `zig build test` to work
test {
    std.testing.refAllDecls(df);
}

pub fn main() !void {

    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    std.debug.print("Damselfly is arriving\n", .{});

    const n1 = comptime df.types.Offset.fromStr(
        " 1 . / " ++
        " . . / " ++
        " . 2   "
    );
    
    std.debug.print("offset is {}\n", .{n1});
}
