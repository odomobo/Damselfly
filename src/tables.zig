pub const Movements = @import("tables/Movements.zig").Movements;

// allows `zig build test` to work
test {
    @import("std").testing.refAllDecls(@This());
}