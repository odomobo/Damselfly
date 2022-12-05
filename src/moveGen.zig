const std = @import("std");
const df = @import("damselfly.zig");

const Position = df.types.Position;
const MoveList = df.types.MoveList;
const Move = df.types.Move;
const Piece = df.types.Piece;
const PieceType = df.types.PieceType;
const Color = df.types.Color;
const bits = df.bits;
const Movements = df.tables.Movements;

// these are pseudo-legal moves; make only legal moves?
pub fn generateMoves(position: *const Position, moveList: *MoveList) void {
    // turns runtime to comptime value
    switch (position.sideToMove) {
        inline else => |sideToMove| generatePawnMoves(sideToMove, position, moveList),
    }

    generateNonsliderMoves(PieceType.Knight, position, moveList);
    generateSliderMoves(PieceType.Bishop, position, moveList);
    generateSliderMoves(PieceType.Rook, position, moveList);
    generateSliderMoves(PieceType.Queen, position, moveList);
    generateNonsliderMoves(PieceType.King, position, moveList);
    // TODO: generate castling moves for king

    // Remove illegal moves.
    // It would be more efficient to observe pins and not generate illegal moves, but this is much simpler to code for now.
    var i: usize = 0;
    while (i < moveList.len) {
        const move = moveList.getItems()[i];
        const updatedPosition = position.makeFromMove(move);
        
        // need to check if we moved ourself into check
        if (updatedPosition.isOtherKingInCheck()) {
            // TODO: select orderedRemove or swapRemove based on a compile-time constant.
            _ = moveList.orderedRemove(i); // this is less efficient than swap remove, but it preserves the ordering which can be nice for debugging
            continue; // without incrementing
        }
        i += 1;
    }
}

fn generatePawnMoves(comptime sideToMove: Color, position: *const Position, moveList: *MoveList) void {
    const otherOccupied = position.getColorBb(sideToMove.other());
    const occupied = position.occupied;

    const pieces = position.getPieceBb(sideToMove, PieceType.Pawn);
    var piecesIterator = pieces.getIterator();
    while (piecesIterator.next()) |pieceVal| {
        const isFinalRank = Movements.pawnIsFinalRank(sideToMove, pieceVal);
        const srcIx = pieceVal.toIndex();

        // generate normal moves
        var normalMoveAllowed = false;
        const normalMoveOffset = Movements.pawnNormalMove(sideToMove);
        if (normalMoveOffset.isAllowedFrom(pieceVal)) {
            const normalMoveDstVal = pieceVal.getWithOffset(normalMoveOffset);
            const normalMoveDstIx = normalMoveDstVal.toIndex();
            normalMoveAllowed = (normalMoveDstVal.val & occupied.val) == 0;

            if (normalMoveAllowed and !isFinalRank) {
                moveList.append(Move{ 
                    .moveType = .{ .normal = true, .quiet = true },
                    .srcIndex = @intCast(i8, srcIx),
                    .dstIndex = @intCast(i8, normalMoveDstIx),
                });
            } else if (normalMoveAllowed and isFinalRank) {
                for ([_]PieceType{PieceType.Queen, PieceType.Knight, PieceType.Rook, PieceType.Bishop}) |pieceType| {
                    moveList.append(Move{ 
                        .moveType = .{ .promotion = true, .quiet = true },
                        .srcIndex = @intCast(i8, srcIx),
                        .dstIndex = @intCast(i8, normalMoveDstIx),
                        .promotionPieceType = pieceType,
                    });
                }
            }
        }

        // generate double moves; can't unless a normal move is also allowed, and starting from the starting square
        if (normalMoveAllowed and Movements.pawnDoubleMoveAllowed(sideToMove, pieceVal)) {
            const doubleMoveOffset = Movements.pawnDoubleMove(sideToMove);
            const doubleMoveDstVal = pieceVal.getWithOffset(doubleMoveOffset);
            const doubleMoveDstIx = doubleMoveDstVal.toIndex();
            const doubleMoveAllowed = (doubleMoveDstVal.val & occupied.val) == 0;

            if (doubleMoveAllowed) {
                moveList.append(Move{ 
                    .moveType = .{ .doubleMove = true, .quiet = true },
                    .srcIndex = @intCast(i8, srcIx),
                    .dstIndex = @intCast(i8, doubleMoveDstIx),
                });
            }
        }

        // generate captures
        for (Movements.pawnCaptures(sideToMove)) |captureOffset| {
            if (!captureOffset.isAllowedFrom(pieceVal))
                continue;
            
            const captureDstVal = pieceVal.getWithOffset(captureOffset);
            const captureDstIx = captureDstVal.toIndex();
            const captureAllowed = (captureDstVal.val & otherOccupied.val) != 0;

            if (captureAllowed and !isFinalRank) {
                moveList.append(Move{ 
                    .moveType = .{ .normal = true, .capture = true },
                    .srcIndex = @intCast(i8, srcIx),
                    .dstIndex = @intCast(i8, captureDstIx),
                });
            } else if (captureAllowed and isFinalRank) {
                for ([_]PieceType{PieceType.Queen, PieceType.Knight, PieceType.Rook, PieceType.Bishop}) |pieceType| {
                    moveList.append(Move{ 
                        .moveType = .{ .promotion = true, .capture = true },
                        .srcIndex = @intCast(i8, srcIx),
                        .dstIndex = @intCast(i8, captureDstIx),
                        .promotionPieceType = pieceType,
                    });
                }
            }

            // en passant!
            if (captureDstIx == position.enPassant) {
                moveList.append(Move{ 
                    .moveType = .{ .enPassant = true, .capture = true },
                    .srcIndex = @intCast(i8, srcIx),
                    .dstIndex = @intCast(i8, captureDstIx),
                });
            }
        }
    }
}

fn generateNonsliderMoves(comptime pieceType: PieceType, position: *const Position, moveList: *MoveList) void {
    var selfOccupied = position.getColorBb(position.sideToMove);

    var pieces = position.getPieceBb(position.sideToMove, pieceType);
    var piecesIterator = pieces.getIterator();
    while (piecesIterator.next()) |pieceVal| {
        var srcIx = pieceVal.toIndex();
        for (Movements.byPieceType(pieceType)) |offset| {
            // skip if that jump isn't allowed from this position
            if (!offset.isAllowedFrom(pieceVal))
                continue;

            // skip if trying to jump to our own piece
            var dstVal = pieceVal.getWithOffset(offset);
            if ((dstVal.val & selfOccupied.val) != 0)
                continue;
            
            var isCapture = (dstVal.val & position.occupied.val) != 0;
            var dstIx = dstVal.toIndex();

            moveList.append(Move{ 
                .moveType = .{ .normal = true, .quiet = !isCapture, .capture = isCapture },
                .srcIndex = @intCast(i8, srcIx),
                .dstIndex = @intCast(i8, dstIx),
            });
        }
    }
}

fn generateSliderMoves(comptime pieceType: PieceType, position: *const Position, moveList: *MoveList) void {
    var selfOccupied = position.getColorBb(position.sideToMove);

    var pieces = position.getPieceBb(position.sideToMove, pieceType);
    var piecesIterator = pieces.getIterator();
    while (piecesIterator.next()) |pieceVal| {
        var srcIx = pieceVal.toIndex();
        for (Movements.byPieceType(pieceType)) |offset| {
            var dstVal = pieceVal;
            while (true) {
                // skip if that jump isn't allowed from this position
                if (!offset.isAllowedFrom(dstVal))
                    break;

                // skip if trying to jump to our own piece
                dstVal = dstVal.getWithOffset(offset);
                if ((dstVal.val & selfOccupied.val) != 0)
                    break;
                
                var isCapture = (dstVal.val & position.occupied.val) != 0;
                var dstIx = dstVal.toIndex();

                moveList.append(Move{ 
                    .moveType = .{ .normal = true, .quiet = !isCapture, .capture = isCapture },
                    .srcIndex = @intCast(i8, srcIx),
                    .dstIndex = @intCast(i8, dstIx),
                });
                
                // can't continue sliding forward after capture
                if (isCapture)
                    break;
            }
        }
    }
}