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
    // unsigned int and float types
    const types_1 = [_]type{ u8, u16, u32 };
    inline for (types_1) |K| {
        // init()
        var map = HashMap(K, u32).init(allocator);

        // deinit()
        defer map.deinit();

        // put()
        for (0..100) |i| {
            var tmp_i: K = undefined;
            if (K == f32 or K == f64) {
                tmp_i = @floatFromInt(i);
            } else {
                tmp_i = @intCast(i);
            }
            const v: u32 = @intCast(i);
            try map.put(tmp_i, v);
        }
        // std.debug.print("{}\n", .{map});
        try testing.expectEqual(false, map.empty());

        // put() with existing key
        for (0..100) |i| {
            var tmp_i: K = undefined;
            if (K == f32 or K == f64) {
                tmp_i = @floatFromInt(i);
            } else {
                tmp_i = @intCast(i);
            }
            const v: u32 = @intCast(i);
            try map.put(tmp_i, v);
        }
        // std.debug.print("{}\n", .{map});
        try testing.expectEqual(false, map.empty());

        // erase()
        for (0..100) |k| {
            var tmp_k: K = undefined;
            if (K == f32 or K == f64) {
                tmp_k = @floatFromInt(k);
            } else {
                tmp_k = @intCast(k);
            }
            try map.erase(tmp_k);
        }
        // std.debug.print("{}\n", .{map}); // should be empty when printed
        try testing.expectEqual(true, map.empty());

        // find()
        for (0..100) |i| {
            var tmp_i: K = undefined;
            if (K == f32 or K == f64) {
                tmp_i = @floatFromInt(i);
            } else {
                tmp_i = @intCast(i);
            }
            const v: u32 = @intCast(i);
            try map.put(tmp_i, v);
        }
        try testing.expectEqual(19, map.find(19));
        try testing.expectEqual(null, map.find(135));
        try testing.expectEqual(7, map.find(7));
        try testing.expectEqual(null, map.find(150));

        // contains()
        try testing.expectEqual(true, map.contains(14));
        try testing.expectEqual(false, map.contains(245));
        try testing.expectEqual(true, map.contains(3));
        try testing.expectEqual(false, map.contains(150));
    }

    const types_2 = [_]type{ i8, i16, i32 };
    inline for (types_2) |K| {
        // init()
        var map = HashMap(K, u32).init(allocator);

        // deinit()
        defer map.deinit();

        // put()
        for (1..100) |i| {
            const tmp_i: K = @intCast(i);
            const v: u32 = @intCast(i);
            try map.put(-tmp_i, v);
        }
        // std.debug.print("{}\n", .{map});
        try testing.expectEqual(false, map.empty());

        // put() with existing key
        for (1..100) |i| {
            const tmp_i: K = @intCast(i);
            const v: u32 = @intCast(i);
            try map.put(-tmp_i, v);
        }
        // std.debug.print("{}\n", .{map});
        try testing.expectEqual(false, map.empty());

        // erase()
        for (1..100) |k| {
            const tmp_k: K = @intCast(k);
            try map.erase(-tmp_k);
        }
        // std.debug.print("{}\n", .{map}); // should be empty when printed
        try testing.expectEqual(true, map.empty());

        // find()
        for (1..100) |i| {
            const tmp_i: K = @intCast(i);
            const v: u32 = @intCast(i);
            try map.put(-tmp_i, v);
        }
        try testing.expectEqual(27, map.find(-27));
        try testing.expectEqual(null, map.find(-101));
        try testing.expectEqual(59, map.find(-59));
        try testing.expectEqual(null, map.find(20));

        // contains()
        try testing.expectEqual(true, map.contains(-14));
        try testing.expectEqual(false, map.contains(45));
        try testing.expectEqual(true, map.contains(-8));
        try testing.expectEqual(false, map.contains(-120));
    }

    const types_3 = [_]type{ f32, f64 };
    inline for (types_3) |K| {
        // init()
        var map = HashMap(K, i32).init(allocator);

        // deinit()
        defer map.deinit();

        // put()
        var i: K = -100.0;
        while (i != 100.0) : (i += 1.0) {
            const tmp_i: K = @floatCast(i);
            const v: i32 = @intFromFloat(i);
            try map.put(tmp_i, v);
        }
        // std.debug.print("{}\n", .{map});
        try testing.expectEqual(false, map.empty());

        // put() with existing key
        i = -100.0;
        while (i != 100.0) : (i += 1.0) {
            const tmp_i: K = @floatCast(i);
            const v: i32 = @intFromFloat(i);
            try map.put(tmp_i, v);
        }
        // std.debug.print("{}\n", .{map});
        try testing.expectEqual(false, map.empty());

        // erase()
        var k: K = -100.0;
        while (k != 100.0) : (k += 1.0) {
            const tmp_k: K = @floatCast(k);
            try map.erase(tmp_k);
        }
        // std.debug.print("{}\n", .{map}); // should be empty when printed
        try testing.expectEqual(true, map.empty());

        // find()
        i = -100.0;
        while (i != 100.0) : (i += 1.0) {
            const tmp_i: K = @floatCast(i);
            const v: i32 = @intFromFloat(i);
            try map.put(tmp_i, v);
        }
        try testing.expectEqual(-27, map.find(-27.0));
        try testing.expectEqual(null, map.find(-101.0));
        try testing.expectEqual(-59, map.find(-59.0));
        try testing.expectEqual(null, map.find(120.0));

        // contains()
        try testing.expectEqual(true, map.contains(-14.0));
        try testing.expectEqual(true, map.contains(35.0));
        try testing.expectEqual(true, map.contains(-8.0));
        try testing.expectEqual(false, map.contains(-120.0));
        try testing.expectEqual(false, map.contains(150.0));
    }

    // init()
    var map = HashMap([]u8, i32).init(allocator);

    // deinit()
    defer map.deinit();

    // put()
    try map.put("Hello"[0..], 1);
    try map.put("World"[0..], 2);
    try map.put("Zig"[0..], 3);
    std.debug.print("{any}\n", .{map});
}
