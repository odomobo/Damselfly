# Debugging Strategy

A core challenge (perhaps _the_ core challenge) when working on a chess engine is understanding what the engine is doing.
A main part of the problem is that an efficient engine is calculating millions of positions per second, but the developer only really sees
the _results_ of this calculation. It becomes very difficult to understand why the engine is doing what it's doing.
If the engine makes a poor move, why did it make this move? If the engine is taking a long time to reach a certain depth, why?

There are several strategies for answering these questions!

The dominant strategy used by the chess community at large (at least, by the stockfish team) is automated engine testing. Whenever a new change
is made, that updated engine is run in an automated tournament which will measure the gain or loss of strength caused by the change. This is good
in general, if your engine is already quite strong and bug-free. In that case, if you accidentally introduce a bug, it will likely show itself in the
form of ELO loss. Similarly, even if an idea is sound, if it costs more in resources than the benefit it provides, then it will also be eliminated.

However, this comes with some drawbacks. One drawback is that if it finds a bug, it can't necessarily show the developer the nature of that bug.
Another drawback is that many games are needed to assess changes in strength, especially if it's a very small change in strength.
Another is that it already needs a strong and bug-free engine for this approach to make sense. This approach can't find existing bugs
in a buggy engine, it can only find new bugs in a bug-free engine.

Another strategy that can be used, specifically to understand what the engine is thinking and what decisions it's making, is to create a debugging probe.
That is, a small piece of code that will check for a certain condition to be met (perhaps a matching zobrist hash in the search tree), and then calls a debugger
interrupt instruction. This will cause any attached debugger to stop at that point, allowing the developer to see what's happening in the engine.

In order for this to be useful in any way, however, the engine has to be repeatable. That means, given some starting condition, repeating the same engine commands 
must result in the exact same result, and all the same intermediate searches and calculations. Note that this is different from search instability; you can have
search instability while still having a repeatable engine. It would just need to follow the same unstable search each time.

In order to allow for this, several things must be true. First off, there must be well-defined cutoff points that indicate a fresh search. That might be the start of your engine,
or (more ideally) it might be the start of any new search. If doing the start of any new search, then any tables must be cleared before any new search.
This is the easiest to reason about, so this is what I will be doing in Damselfly.

Things to keep in mind: any random number generation must be made from a well-defined starting seed, which must be set at any cutoff point.
Ideally, no random number generation will be used, but sometimes it's desired (e.g. in the case of weakening the engine). As mentioned, any tables
or caches must be cleared between cutoff points. Finally, multithreading must either be entirely disabled, or effectively disabled (making multithreaded
search execute in a well-defined order based on some criteria, maybe allowing each thread to execute 1 step in a round-robin fashion, which would cause
the engine to be effectively single-threaded while still allowing for debugging of multi-threaded search code).

Another strategy that can be used is to dump the entire search tree of a particular search to disk. This also depends on a repeatable engine, because you 
can only dump after you've identified a problem, because the dump for a search will be enormous. Then there would need to be some GUI tool which can view a search dump
and allow you to explore it.

A hybrid strategy would be combining the above two: creating a GUI application that will allow you to explore a search tree, but it does so by re-repeating the search,
and only probing for the new information it needs.

A simpler hybrid strategy is similar, but uses an external GUI instead of one created specifically for the engine. This would be some kind of a complex probe command that
would give all the lines that are desired, and whenever any line is reached within the search, then that information would be gather. Finally, after the search is complete, that
information would be exported as PGN with annotations per move giving any engine information desired. This could be automatically saved to the clipboard, or provided as a lichess link.