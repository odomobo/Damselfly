pub const Movements = @import("tables/Movements.zig").Movements;
pub const castling = @import("tables/castling.zig");

// allows `zig build test` to work
test {
    @import("std").testing.refAllDecls(@This());
}