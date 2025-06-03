const std = @import("std");

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
        allocator: std.mem.Allocator,

        pub fn init(allocator: std.mem.Allocator) Self {
            return Self{
                .head = null,
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
            return self.head == null;
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
        }

        pub fn pop(self: *Self) void {
            const node = self.head;
            if (node) |_| {
                self.head = self.head.?.prev;
                self.allocator.destroy(node.?);
            }
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
