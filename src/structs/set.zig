const std = @import("std");
const ArrayList = std.ArrayList;
const Order = std.math.Order;
const default_cmp = @import("cmp.zig").default_cmp;

pub fn Set(comptime T: type, comptime cmp_fn: ?fn (anytype, anytype) anyerror!Order) type {
    return struct {
        const Self = @This();
        const SetNode = struct {
            value: T,
            left: ?*SetNode,
            right: ?*SetNode,

            fn init(allocator: std.mem.Allocator) !*SetNode {
                return try allocator.create(SetNode);
            }
        };

        root: ?*SetNode,
        size: u32,
        allocator: std.mem.Allocator,

        pub fn init(allocator: std.mem.Allocator) Self {
            return Self{
                .root = null,
                .size = 0,
                .allocator = allocator,
            };
        }

        fn deinit_nodes(root: ?*SetNode, allocator: std.mem.Allocator) void {
            if (root) |node| {
                deinit_nodes(node.left, allocator);
                deinit_nodes(node.right, allocator);
                allocator.destroy(node);
            }
        }

        pub fn deinit(self: *Self) void {
            deinit_nodes(self.root, self.allocator);
        }

        pub fn empty(self: *Self) bool {
            return self.root == null;
        }

        fn inorder(root: ?*SetNode, nodes: *ArrayList(?*SetNode)) void {
            if (root) |node| {
                if (node.left != null) inorder(node.left, nodes);
                nodes.appendAssumeCapacity(node);
                if (node.right != null) inorder(node.right, nodes);
            }
        }

        fn get_nodes(self: *Self, nodes: *ArrayList(?*SetNode)) void {
            inorder(self.root, nodes);
        }

        fn reorder(nodes: []?*SetNode, l: i32, r: i32) ?*SetNode {
            var node: ?*SetNode = null;

            if (l > r) return null;

            const m = @divFloor(l + r, 2);
            node = nodes[@intCast(m)];
            node.?.left = reorder(nodes, l, m - 1);
            node.?.right = reorder(nodes, m + 1, r);

            return node;
        }

        fn balance(self: *Self) !void {
            var nodes = ArrayList(?*SetNode).init(self.allocator);
            try nodes.ensureTotalCapacity(self.size);
            defer nodes.deinit();

            self.get_nodes(&nodes);
            if (self.size > 1) {
                self.root = reorder(nodes.items, 0, @intCast(self.size - 1));
            }
        }

        fn insert_node(root: ?*SetNode, value: T, allocator: std.mem.Allocator) !?*SetNode {
            if (root == null) {
                const node = try SetNode.init(allocator);
                node.* = SetNode{
                    .value = value,
                    .left = null,
                    .right = null,
                };
                return node;
            }

            const cmp_res = (cmp_fn orelse default_cmp)(value, root.?.value) catch |err| return err;
            if (cmp_res == Order.lt) {
                root.?.left = try insert_node(root.?.left, value, allocator);
            } else {
                root.?.right = try insert_node(root.?.right, value, allocator);
            }

            return root;
        }

        pub fn insert(self: *Self, value: anytype) !void {
            const V = @TypeOf(value);
            if (V == comptime_float and (T == f32 or T == f64)) {
                self.root = try insert_node(self.root, @as(T, value), self.allocator);
            } else if (V == comptime_int and (T == i32 or T == u32 or T == i64 or T == u64)) {
                self.root = try insert_node(self.root, @as(T, value), self.allocator);
            } else if (V == T) {
                self.root = try insert_node(self.root, value, self.allocator);
            } else {
                return error.TypeMismatch;
            }
            self.size += 1;
            try self.balance();
        }

        fn get_successor(root: ?*SetNode) ?*SetNode {
            var curr = root.?.right;
            while (curr != null and curr.?.left != null) {
                curr = curr.?.left;
            }
            return curr;
        }

        fn delete_node(root: ?*SetNode, value: T, allocator: std.mem.Allocator, deleted: *bool) !?*SetNode {
            if (root) |node| {
                const cmp_res = (cmp_fn orelse default_cmp)(value, node.value) catch |err| return err;

                if (cmp_res == Order.gt) {
                    node.right = try delete_node(node.right, value, allocator, deleted);
                } else if (cmp_res == Order.lt) {
                    node.left = try delete_node(node.left, value, allocator, deleted);
                } else {
                    if (node.left == null) {
                        deleted.* = true;
                        const right_child = node.right;
                        allocator.destroy(node);
                        return right_child;
                    }

                    if (node.right == null) {
                        deleted.* = true;
                        const left_child = node.left;
                        allocator.destroy(node);
                        return left_child;
                    }

                    const succ = get_successor(node);
                    node.value = succ.?.value;
                    node.right = try delete_node(node.right, succ.?.value, allocator, deleted);
                }

                return node;
            }

            return root;
        }

        pub fn delete(self: *Self, value: anytype) !void {
            var deleted = false;
            const V = @TypeOf(value);
            if (V == comptime_float and (T == f32 or T == f64)) {
                self.root = try delete_node(self.root, @as(T, value), self.allocator, &deleted);
            } else if (V == comptime_int and (T == i32 or T == u32 or T == i64 or T == u64)) {
                self.root = try delete_node(self.root, @as(T, value), self.allocator, &deleted);
            } else if (V == T) {
                self.root = try delete_node(self.root, value, self.allocator, &deleted);
            } else {
                return error.TypeMismatch;
            }

            if (deleted) {
                self.size -= 1;
                try self.balance();
            }
        }

        fn find_node(root: ?*SetNode, value: T) !bool {
            if (root == null) return false;

            const cmp_res = (cmp_fn orelse default_cmp)(value, root.?.value) catch |err| return err;
            if (cmp_res == Order.eq) return true;

            if (cmp_res == Order.gt) {
                return find_node(root.?.right, value);
            } else {
                return find_node(root.?.left, value);
            }
        }

        pub fn contains(self: *Self, value: anytype) !bool {
            const V = @TypeOf(value);
            if (V == comptime_float and (T == f32 or T == f64)) {
                return try find_node(self.root, value);
            } else if (V == comptime_int and (T == i32 or T == u32 or T == i64 or T == u64)) {
                return try find_node(self.root, @as(T, value));
            } else if (V == T) {
                return try find_node(self.root, value);
            } else {
                return error.TypeMismatch;
            }
        }

        pub fn format(self: Self, comptime fmt: []const u8, opts: std.fmt.FormatOptions, writer: anytype) !void {
            _ = fmt;
            _ = opts;

            var nodes = ArrayList(?*SetNode).init(self.allocator);
            try nodes.ensureTotalCapacity(self.size);
            defer nodes.deinit();

            @constCast(&self).get_nodes(&nodes);
            try writer.writeAll("[ ");
            for (nodes.items) |node| {
                try writer.print("{} ", .{node.?.value});
            }
            try writer.writeAll("]");
        }
    };
}
