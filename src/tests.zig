const std = @import("std");

const Stack = @import("root.zig").Stack;
const Queue = @import("root.zig").Queue;

const testing = std.testing;
const allocator = testing.allocator;

test "Stack" {
    // init()
    var stack = Stack(u32).init(allocator);

    // deinit()
    defer stack.deinit();

    // empty()
    try testing.expectEqual(true, stack.empty());

    // push()
    try stack.push(10);
    try stack.push(20);
    try stack.push(30);
    try testing.expectEqual(false, stack.empty());

    // top()
    try testing.expectEqual(30, stack.top().?);

    // pop();
    stack.pop();
    try testing.expectEqual(20, stack.top().?);
    stack.pop();
    stack.pop();
    // pop() on empty stack
    stack.pop();
    stack.pop();
    try testing.expectEqual(true, stack.empty());
}

test "Queue" {
    // init()
    var queue = Queue(u32).init(allocator);

    // deinit()
    defer queue.deinit();

    // empty()
    try testing.expectEqual(true, queue.empty());

    // push()
    try queue.push(10);
    try queue.push(20);
    try queue.push(30);
    try queue.push(40);
    try testing.expectEqual(false, queue.empty());

    // first()
    try testing.expectEqual(10, queue.first().?);

    // last()
    try testing.expectEqual(40, queue.last().?);

    // pop()
    queue.pop();
    try testing.expectEqual(20, queue.first().?);
    queue.pop();
    queue.pop();
    // pop() on empty queue
    queue.pop();
    queue.pop();
    queue.pop();
    try testing.expectEqual(true, queue.empty());
}
