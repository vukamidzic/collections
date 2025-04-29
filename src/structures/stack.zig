const std = @import("std");
const expectEqual = std.testing.expectEqual;
const test_allocator = std.testing.allocator;

pub fn Stack(comptime T: type) type {
    return struct {
        const Self = @This();
        const StackNode = struct {
            value: T,
            prev: ?*StackNode,

            fn init(allocator: std.mem.Allocator) !*StackNode {
                return try allocator.create(StackNode);
            }
        };

        head: ?*StackNode,
        size: u32,
        allocator: std.mem.Allocator,

        pub fn init(allocator: std.mem.Allocator) Self {
            return Self{
                .head = null,
                .size = 0,
                .allocator = allocator,
            };
        }

        pub fn deinit(self: *Self) void {
            while (self.head) |node| {
                self.head = node.prev;
                self.allocator.destroy(node);
            }
        }

        pub fn empty(self: *Self) bool {
            return self.size == 0;
        }

        pub fn top(self: *Self) ?T {
            if (self.head) |head| {
                return head.value;
            }
            return null;
        }

        pub fn push(self: *Self, value: T) !void {
            var new_head = try StackNode.init(self.allocator);
            new_head.value = value;
            new_head.prev = self.head;
            self.head = new_head;
            self.size += 1;
        }

        pub fn pop(self: *Self) void {
            const node = self.head;
            defer self.allocator.destroy(node.?);

            self.head = self.head.?.prev;
            self.size -= 1;
        }

        pub fn format(self: Self, comptime fmt: []const u8, opts: std.fmt.FormatOptions, writer: anytype) !void {
            _ = fmt;
            _ = opts;

            try writer.writeAll("[ ");
            var curr = self.head;
            while (curr) |node| {
                try writer.print("{} ", .{node.value});
                curr = node.prev;
            }
            try writer.writeAll("]");
        }
    };
}

test "Stack.init()" {
    const stack = Stack(i32).init(test_allocator);
    try expectEqual(0, stack.size);
}

test "Stack.deinit()" {
    var stack = Stack(i32).init(test_allocator);
    try expectEqual(0, stack.size);

    stack.deinit();
    try expectEqual(null, stack.head);
}

test "Stack.push()" {
    var stack = Stack(i32).init(test_allocator);
    defer stack.deinit();
    try stack.push(1);
    try stack.push(2);
    try stack.push(3);
    try expectEqual(3, stack.size);
}

test "Stack.top()" {
    var stack = Stack(i32).init(test_allocator);
    defer stack.deinit();
    try stack.push(1);
    try stack.push(2);
    try stack.push(3);
    try expectEqual(3, stack.size);

    try expectEqual(3, stack.top().?);
}

test "Stack.pop()" {
    var stack = Stack(i32).init(test_allocator);
    defer stack.deinit();
    try stack.push(1);
    try stack.push(2);
    try stack.push(3);
    try stack.push(4);
    try stack.push(5);
    try stack.push(6);

    try expectEqual(6, stack.top().?);

    stack.pop();
    stack.pop();
    try expectEqual(4, stack.top().?);
}

test "Stack.empty()" {
    var stack = Stack(i32).init(test_allocator);
    defer stack.deinit();
    try stack.push(1);
    try stack.push(2);
    try stack.push(3);

    stack.pop();
    stack.pop();
    stack.pop();
    try expectEqual(true, stack.empty());
}

test "Stack.format()" {
    var stack = Stack(i32).init(test_allocator);
    defer stack.deinit();
    try stack.push(1);
    try stack.push(2);
    try stack.push(3);
    try stack.push(4);
    try stack.push(5);

    var stack_string = try std.fmt.allocPrint(
        test_allocator,
        "{s}",
        .{stack},
    );
    try expectEqual(true, std.mem.eql(u8, stack_string, "[ 5 4 3 2 1 ]"));
    test_allocator.free(stack_string);

    inline for (0..5) |_| {
        stack.pop();
    }

    stack_string = try std.fmt.allocPrint(
        test_allocator,
        "{s}",
        .{stack},
    );
    try expectEqual(true, std.mem.eql(u8, stack_string, "[ ]"));
    test_allocator.free(stack_string);
}
