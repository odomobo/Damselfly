# Root-Move Ordering

Instead of doing a normal search at the root, like you normally implement in chess engines, why have a move picker that picks the next logical move to evaluate, along with some information like the bounds it should be evaluating. It can also determine if we're ever panicking, like when all moves are currently failing low.

It would pick next move based on some criteria, like:

1. If there's ever a move which failed high (with non-infinite beta), then that move must be re-searched immediately, with at least a higher upper bounds (maybe infinite)
2. If highest evaluated move is failed low, then set panicking to be true.
3. If the highest evaluated move has failed-low, re-search the move with the highest value with the previous search criteria, with a wider bounds (which might be from a previous depth).
4. Use best current move to determine some kind of bounds. Search the highest evaluated move from a previous depth. If re-searching the best current move, perhaps use a different (wider) bounds.
5. If no moves from a previous depth, increase depth and repeat.

Then, if ever interrupted, it would always go to the move picker and pick the move with the highest value. If time is out but panicking, allot bonus time until panicking has stopped.