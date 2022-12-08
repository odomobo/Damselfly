# Allocators

Zig has a rich system for allocators. For any code which isn't in the hot path (isn't part of the normal search tree), instead of doing that, we'll just use a general purpose allocator. This will be good enough, and should make things easier. If allocations fail, we'll just panic, because we don't want to handle out-of-memory issues.