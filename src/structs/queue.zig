const std = @import("std");

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
        allocator: std.mem.Allocator,

        pub fn init(allocator: std.mem.Allocator) Self {
            return Self{
                .front = null,
                .back = null,
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
            return self.front == null and self.back == null;
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

        pub fn push(self: *Self, value: anytype) !void {
            var node = try QueueNode.init(self.allocator);

            const V = @TypeOf(value);
            if (V == comptime_float and (T == f32 or T == f64)) {
                node.value = @as(T, value);
            } else if (V == comptime_int and (T == i32 or T == u32 or T == i64 or T == u64)) {
                node.value = @as(T, value);
            } else if (V == T) {
                node.value = value;    
            } else {
                return error.TypeMismatch;
            }
            
            node.prev = null;

            if (self.front == null and self.back == null) {
                self.front = node;
                self.back = node;
            } else {
                self.back.?.prev = node;
                self.back = node;
            }
        }

        pub fn pop(self: *Self) void {
            const node = self.front;
            if (node) |_| {
                if (self.front == self.back) {
                    self.back = null;
                    self.front = null;
                } else {
                    self.front = self.front.?.prev;
                }
                self.allocator.destroy(node.?);
            }
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
