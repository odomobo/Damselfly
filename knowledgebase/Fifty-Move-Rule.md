# Fifty-Move Rule

Although an engine can easily identify a draw by the 50-move rule, it's quite beneficial if the engine doesn't take it into
account when evaluating a position. This is because, if the engine thinks it's winning, yet is about to reach a draw by the 50-move rule,
that's an indication that the engine's strategy doesn't give it the ability to make any progress in the current position. If it
was able to make progress, it already would have done so, either already winning the game, or already resetting the 50-move rule.
Since neither of these has happened, that's an indication that the engine cannot make progress. What this means is that if the
engine were made aware of the 50-move rule, it would be incentivized to make a sub-optimal move to reset the 50-move timer.
That is because, let's say it thinks it's at a +5.0, and it's about to trigger the 50-move rule, then it will happily give a pawn
to reset the 50-move rule timer. This is because +4.0 is higher than 0.0 . However, if it can't make progress given the current
state, it almost certainly won't be able to make progress after sacrificing a pawn/piece, and is giving an opportunity for the
opponent to come back into the game, via the suboptimal move.