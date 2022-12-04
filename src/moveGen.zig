const std = @import("std");
const df = @import("damselfly.zig");

const Position = df.types.Position;
const MoveList = df.types.MoveList;
const Move = df.types.Move;
const Piece = df.types.Piece;
const PieceType = df.types.PieceType;
const Color = df.types.Color;
const bits = df.bits;

// these are pseudo-legal moves; make only legal moves?
pub fn generateMoves(position: *const Position, moveList: *MoveList) void {
    // TODO: generatePawnMoves
    generateNonsliderMoves(PieceType.Knight, position, moveList);
    generateSliderMoves(PieceType.Bishop, position, moveList);
    generateSliderMoves(PieceType.Rook, position, moveList);
    generateSliderMoves(PieceType.Queen, position, moveList);
    generateNonsliderMoves(PieceType.King, position, moveList);

    // TODO: remove illegal moves???
}

fn generateNonsliderMoves(comptime pieceType: PieceType, position: *const Position, moveList: *MoveList) void {
    var selfOccupied = position.getColorBb(position.sideToMove);

    var pieces = position.getPieceBb(position.sideToMove, pieceType);
    var piecesIterator = pieces.getIterator();
    while (piecesIterator.next()) |pieceVal| {
        var srcIx = pieceVal.toIndex();
        for (df.tables.Movements.byPieceType(pieceType)) |offset| {
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
        for (df.tables.Movements.byPieceType(pieceType)) |offset| {
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