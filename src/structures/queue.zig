const std = @import("std");
const expectEqual = std.testing.expectEqual;
const test_allocator = std.testing.allocator;

pub fn Queue(comptime T: type) type {
    return struct {
        const Self = @This();
        const QueueNode = struct {
            value: T,
            prev: ?*QueueNode,

            fn init(allocator: std.mem.Allocator) !*QueueNode {
                return try allocator.create(QueueNode);
            }
        };

        front: ?*QueueNode,
        back: ?*QueueNode,
        size: u32,
        allocator: std.mem.Allocator,

        pub fn init(allocator: std.mem.Allocator) Self {
            return Self{
                .front = null,
                .back = null,
                .size = 0,
                .allocator = allocator,
            };
        }

        pub fn deinit(self: *Self) void {
            while (self.front) |node| {
                self.front = node.prev;
                self.allocator.destroy(node);
            }
        }

        pub fn empty(self: *Self) bool {
            return self.size == 0;
        }

        pub fn first(self: *Self) ?T {
            if (self.front) |front| {
                return front.value;
            }
            return null;
        }

        pub fn last(self: *Self) ?T {
            if (self.back) |back| {
                return back.value;
            }
            return null;
        }

        pub fn push(self: *Self, value: T) !void {
            var node = try QueueNode.init(self.allocator);
            node.value = value;
            node.prev = null;

            if (self.front == null and self.back == null) {
                self.front = node;
                self.back = node;
            } else {
                self.back.?.prev = node;
                self.back = node;
            }

            self.size += 1;
        }

        pub fn pop(self: *Self) void {
            const node = self.front;
            defer self.allocator.destroy(node.?);

            self.front = self.front.?.prev;
            self.size -= 1;
        }

        pub fn format(self: Self, comptime fmt: []const u8, opts: std.fmt.FormatOptions, writer: anytype) !void {
            _ = fmt;
            _ = opts;

            try writer.writeAll("[ ");
            var curr = self.front;
            while (curr) |node| {
                try writer.print("{} ", .{node.value});
                curr = node.prev;
            }
            try writer.writeAll("]");
        }
    };
}

test "Queue.init()" {
    var queue = Queue(i32).init(test_allocator);
    defer queue.deinit();
    try expectEqual(0, queue.size);
}

test "Queue.push()" {
    var queue = Queue(i32).init(test_allocator);
    defer queue.deinit();
    try queue.push(10);
    try queue.push(20);
    try queue.push(30);
    try expectEqual(3, queue.size);
}

test "Queue.pop()" {
    var queue = Queue(i32).init(test_allocator);
    defer queue.deinit();
    try queue.push(10);
    try queue.push(20);
    try queue.push(30);
    try expectEqual(3, queue.size);

    queue.pop();
    queue.pop();
    try expectEqual(1, queue.size);
}

test "Queue.{first()+last()+empty()}" {
    var queue = Queue(i32).init(test_allocator);
    defer queue.deinit();
    try queue.push(10);
    try queue.push(20);
    try queue.push(30);
    try queue.push(40);
    try queue.push(50);
    try expectEqual(10, queue.first().?);
    try expectEqual(50, queue.last().?);

    queue.pop();
    queue.pop();
    try expectEqual(30, queue.first().?);
    try expectEqual(50, queue.last().?);

    queue.pop();
    queue.pop();
    queue.pop();
    try expectEqual(true, queue.empty());
}

test "Queue.format()" {
    var queue = Queue(i32).init(test_allocator);
    defer queue.deinit();
    try queue.push(10);
    try queue.push(20);
    try queue.push(30);
    try queue.push(40);
    try queue.push(50);

    var queue_string = try std.fmt.allocPrint(
        test_allocator,
        "{s}",
        .{queue},
    );
    try expectEqual(true, std.mem.eql(u8, queue_string, "[ 10 20 30 40 50 ]"));
    test_allocator.free(queue_string);

    inline for (0..5) |_| {
        queue.pop();
    }

    queue_string = try std.fmt.allocPrint(
        test_allocator,
        "{s}",
        .{queue},
    );
    try expectEqual(true, std.mem.eql(u8, queue_string, "[ ]"));
    test_allocator.free(queue_string);
}
