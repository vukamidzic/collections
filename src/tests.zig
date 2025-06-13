const std = @import("std");

const Stack = @import("root.zig").Stack;
const Queue = @import("root.zig").Queue;
const Set = @import("root.zig").Set;
const HashMap = @import("root.zig").HashMap;

const default_cmp = @import("root.zig").default_cmp;
const Order = std.math.Order;

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

    // push() invalid type
    try testing.expectError(error.TypeMismatch, stack.push(10.0));
    try testing.expectError(error.TypeMismatch, stack.push("Hello World"));
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

    // push() invalid type
    try testing.expectError(error.TypeMismatch, queue.push(true));
    try testing.expectError(error.TypeMismatch, queue.push(69.420));
    try testing.expectError(error.TypeMismatch, queue.push("Hello"));
}

test "Set" {
    //init()
    var set = Set(i32, null).init(allocator);

    //deinit()
    defer set.deinit();

    //empty()
    try testing.expectEqual(true, set.empty());

    //insert()
    try set.insert(10);
    try set.insert(20);
    try set.insert(13);
    try set.insert(30);
    try set.insert(5);
    try set.insert(1);
    try set.insert(8);
    try testing.expectEqual(false, set.empty());
    try testing.expectEqual(7, set.size);

    // contains()
    try testing.expectEqual(true, set.contains(10));
    try testing.expectEqual(true, set.contains(8));
    try testing.expectEqual(false, set.contains(33));

    // delete()
    try set.delete(10);
    try set.delete(20);
    try testing.expectEqual(5, set.size);

    // contains() after delete
    try testing.expectEqual(false, set.contains(10));
    try testing.expectEqual(false, set.contains(20));
    try testing.expectEqual(true, set.contains(13));
    try testing.expectEqual(true, set.contains(30));

    // delete the rest of elements
    try set.delete(13);
    try set.delete(30);
    try set.delete(5);
    try set.delete(1);
    try set.delete(8);
    try testing.expectEqual(true, set.empty());
    try testing.expectEqual(0, set.size);

    // adding and deleting elements of unvalid type
    try set.insert(10);
    try set.insert(5);
    try set.insert(20);
    try testing.expectError(error.TypeMismatch, set.insert(10.0));
    try testing.expectError(error.TypeMismatch, set.delete(10.0));
    try testing.expectError(error.TypeMismatch, set.insert("hello"));
    try testing.expectError(error.TypeMismatch, set.delete(true));
}

test "HashMap" {
    // init()
    var map = HashMap(u32, u32).init(allocator);

    // deinit()
    defer map.deinit();

    // put()
    inline for (0..20) |i| {
        try map.put(i, i);
    }
    // std.debug.print("{}\n", .{map});
    try testing.expectEqual(false, map.empty());

    // put() with existing key
    inline for (0..20) |i| {
        try map.put(i, 20 - i - 1);
    }
    // std.debug.print("{}\n", .{map});
    try testing.expectEqual(false, map.empty());

    // erase()
    inline for (0..20) |k| {
        try map.erase(k);
    }
    // std.debug.print("{}\n", .{map}); // should be empty when printed
    try testing.expectEqual(true, map.empty());

    // find()
    inline for (0..20) |i| {
        try map.put(i, i);
    }
    try testing.expectEqual(19, map.find(19));
    try testing.expectEqual(null, map.find(35));
    try testing.expectEqual(7, map.find(7));
    try testing.expectEqual(null, map.find(20));

    // contains()
    try testing.expectEqual(true, map.contains(14));
    try testing.expectEqual(false, map.contains(45));
    try testing.expectEqual(true, map.contains(3));
    try testing.expectEqual(false, map.contains(50));
}
