const std = @import("std");
const df = @import("../damselfly.zig");

const Bitboard = df.types.Bitboard;
const Offset = df.types.Offset;
const bitboards = df.bitboards;

pub fn init() void {
    allowedFromTableInner = createAllowedFromTable();
}

// don't touch this; initialized at startup
pub var allowedFromTableInner = [_]Bitboard{0} ** allowedFromTableSize;
// TODO: get rid of this once zig compiler issue is fixed
pub const allowedFromTable = &allowedFromTableInner;
pub const maxAllowedFromCardinalDistance: isize = 2;
pub const minAllowedFromOffset = Offset.fromXY(-maxAllowedFromCardinalDistance, -maxAllowedFromCardinalDistance);
pub const maxAllowedFromOffset = Offset.fromXY(maxAllowedFromCardinalDistance, maxAllowedFromCardinalDistance);
pub const allowedFromTableSize = maxAllowedFromOffset.val - minAllowedFromOffset.val + 1;

fn createAllowedFromTable() [allowedFromTableSize]Bitboard {
    var ret = [_]Bitboard{0} ** allowedFromTableSize;

    var offsY: isize = -maxAllowedFromCardinalDistance;
    while(offsY <= maxAllowedFromCardinalDistance) : (offsY += 1)
    {
        var offsX: isize = -maxAllowedFromCardinalDistance;
        while(offsX <= maxAllowedFromCardinalDistance) : (offsX += 1)
        {
            var curOffset = Offset.fromXY(offsX, offsY);
            var curBitboard: Bitboard = 0;

            var bbY: isize = 0;
            while(bbY < 8) : (bbY += 1)
            {
                var bbX: isize = 0;
                while(bbX < 8) : (bbX += 1)
                {
                    // if can safely jump by offset from current position, then it's safe and we set the bit
                    if (
                        bbX + offsX >= 0 and
                        bbX + offsX < 8 and
                        bbY + offsY >= 0 and
                        bbY + offsY < 8
                    )
                    {
                        bitboards.setXY(&curBitboard, bbX, bbY);
                    }
                }
            }

            var index = curOffset.val - minAllowedFromOffset.val;
            ret[@intCast(usize, index)] = curBitboard;
        }
    }
    
    return comptime ret;
}
