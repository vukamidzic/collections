const std = @import("std");
const expectEqual = std.testing.expectEqual;

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
    };
}

test "Stack.init()" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const stack = Stack(i32).init(allocator);
    try expectEqual(0, stack.size);
}

test "Stack.deinit()" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var stack = Stack(i32).init(allocator);
    try expectEqual(0, stack.size);

    stack.deinit();
    try expectEqual(null, stack.head);
}

test "Stack.push()" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var stack = Stack(i32).init(allocator);
    defer stack.deinit();
    try stack.push(1);
    try stack.push(2);
    try stack.push(3);
    try expectEqual(3, stack.size);
}

test "Stack.top()" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var stack = Stack(i32).init(allocator);
    defer stack.deinit();
    try stack.push(1);
    try stack.push(2);
    try stack.push(3);
    try expectEqual(3, stack.size);

    try expectEqual(3, stack.top().?);
}

test "Stack.pop()" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var stack = Stack(i32).init(allocator);
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
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var stack = Stack(i32).init(allocator);
    defer stack.deinit();
    try stack.push(1);
    try stack.push(2);
    try stack.push(3);

    stack.pop();
    stack.pop();
    stack.pop();
    try expectEqual(true, stack.empty());
}
