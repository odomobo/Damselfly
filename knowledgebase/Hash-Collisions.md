# Hash Collisions

Hash collision probability can be calculated with the below formula:

1 - e^-( (n choose 2) / 2^b )

Where "n" is the number of hashtable entries, and b is the number of bits in the hash key (including the number of unique bits in the hash entry lookup).

So if there are 2^20 hashtable entries, and each hashtable entry has a 32-bit hash key, then b is going to be 20+32 = 52. This is assuming there are no
shared bits between the key of the hashtable entries and the hash key, of course.

In practice, this number is a bit more difficult to calculate, because the above calculations doesn't take into account the total number of hash probes,
which will affect the total calculation. This is just assuming there are n total hash probes, and the hash table can store all the probes. Anyhow, this
will give you a rough estimate, that will get you within 1 or 2 orders of magnitude of the chance of a hash collision on any particular search.