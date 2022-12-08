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

pub fn init() void {
    tables.init();
}

// allows `zig build test` to work
test {
    tables.init(); // it's important this is called here before any tests are run

    @import("std").testing.refAllDecls(@This());
}