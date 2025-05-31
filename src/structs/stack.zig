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
            if (node) |_| {
                defer self.allocator.destroy(node.?);
                self.head = self.head.?.prev;
                self.size -= 1;
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
