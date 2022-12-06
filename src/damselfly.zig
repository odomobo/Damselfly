pub const types = @import("types.zig");
pub const tables = @import("tables.zig");
pub const indexes = @import("indexes.zig");
pub const bitboards = @import("bitboards.zig");
pub const moveGen = @import("moveGen.zig");
pub const scores = @import("scores.zig");
pub const debug = @import("debug.zig");
pub const StaticArrayList = @import("StaticArrayList.zig").StaticArrayList;

// allows `zig build test` to work
test {
    @import("std").testing.refAllDecls(@This());
}