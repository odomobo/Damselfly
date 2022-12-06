pub const movements = @import("tables/movements.zig");
pub const castling = @import("tables/castling.zig");

// allows `zig build test` to work
test {
    @import("std").testing.refAllDecls(@This());
}