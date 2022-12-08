const std = @import("std");

pub const types = @import("types.zig");
pub const tables = @import("tables.zig");
pub const indexes = @import("indexes.zig");
pub const bitboards = @import("bitboards.zig");
pub const moveGen = @import("moveGen.zig");
pub const scores = @import("scores.zig");
pub const debug = @import("debug.zig");
pub const StaticArrayList = @import("StaticArrayList.zig").StaticArrayList;
pub const constants = @import("constants.zig");
pub const zobrist = @import("zobrist.zig");

// this will probably cause a compiler crash once we try to use compile options within tests
pub const compileOptions =
    if (@import("builtin").is_test)
        types.CompileOptions{
            .configuration = "test",
            .paranoid = true,
        }
    else if (@hasDecl(@import("root"), "compileOptions")) 
        @import("root").compileOptions 
    else 
        types.CompileOptions{}
;

pub var allocator: std.mem.Allocator = undefined;

pub fn init(alloc: std.mem.Allocator) void {
    allocator = alloc;

    tables.init();
}

// allows `zig build test` to work
test {
    tables.init(std.testing.allocator); // it's important this is called here before any tests are run

    @import("std").testing.refAllDecls(@This());
}

test "paranoid tests" {
    try std.testing.expect(compileOptions.paranoid == true);
}