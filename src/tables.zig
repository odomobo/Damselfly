pub const movements = @import("tables/movements.zig");
pub const castling = @import("tables/castling.zig");
pub const offsets = @import("tables/offsets.zig");
pub const zobrist = @import("tables/zobrist.zig");

pub fn init() void {
    offsets.init();
    zobrist.init();
}

// allows `zig build test` to work
test {
    @import("std").testing.refAllDecls(@This());
}