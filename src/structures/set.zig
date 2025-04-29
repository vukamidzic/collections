const std = @import("std");
const cmp = @import("../cmp.zig");
const ArrayList = std.ArrayList;
const expectEqual = std.testing.expectEqual;
const test_allocator = std.testing.allocator;

pub fn Set(comptime T: type, comptime cmp_fn: fn (anytype, anytype) cmp.CmpErr!cmp.CmpResult) type {
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
            return self.size == 0;
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

            errdefer |err| std.log.err("{s}\n", .{@errorName(err)});

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

            const cmp_res = cmp_fn(value, root.?.value) catch |err| return err;
            if (cmp_res == cmp.CmpResult.LT) {
                root.?.left = try insert_node(root.?.left, value, allocator);
            } else {
                root.?.right = try insert_node(root.?.right, value, allocator);
            }

            return root;
        }

        pub fn insert(self: *Self, value: T) !void {
            self.root = try insert_node(self.root, value, self.allocator);
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
                const cmp_res = cmp_fn(value, node.value) catch |err| return err;

                if (cmp_res == cmp.CmpResult.GT) {
                    node.right = try delete_node(node.right, value, allocator, deleted);
                } else if (cmp_res == cmp.CmpResult.LT) {
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

        pub fn delete(self: *Self, value: T) !void {
            var deleted = false;
            self.root = try delete_node(self.root, value, self.allocator, &deleted);

            if (deleted) {
                self.size -= 1;
                try self.balance();
            }
        }

        fn find_node(root: ?*SetNode, value: T) !bool {
            if (root == null) return false;

            const cmp_res = cmp_fn(value, root.?.value) catch |err| return err;
            if (cmp_res == cmp.CmpResult.EQ) return true;

            if (cmp_res == cmp.CmpResult.GT) {
                return find_node(root.?.right, value);
            } else {
                return find_node(root.?.left, value);
            }
        }

        pub fn contains(self: *Self, value: T) !bool {
            return try find_node(self.root, value);
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

test "Set.init()" {
    const set = Set(i32, cmp.default_cmp).init(test_allocator);
    try expectEqual(0, set.size);
}

test "Set.insert()" {
    var set = Set(i32, cmp.default_cmp).init(test_allocator);
    defer set.deinit();

    try set.insert(91);
    try set.insert(99);
    try set.insert(30);
    try set.insert(72);
    try set.insert(40);
    try set.insert(80);
    try expectEqual(6, set.size);
}

test "Set.delete()" {
    var set = Set(i32, cmp.default_cmp).init(test_allocator);
    defer set.deinit();

    try set.insert(91);
    try set.insert(99);
    try set.insert(30);
    try set.insert(72);
    try set.insert(40);
    try set.insert(80);
    try expectEqual(6, set.size);

    try set.delete(10);
    try expectEqual(6, set.size);

    try set.delete(91);
    try expectEqual(5, set.size);
}

test "Set.contains()" {
    var set = Set(i32, cmp.default_cmp).init(test_allocator);
    defer set.deinit();

    try set.insert(35);
    try set.insert(20);
    try set.insert(10);
    try set.insert(15);
    try set.insert(50);
    try set.insert(40);
    try set.insert(70);
    try expectEqual(7, set.size);

    try expectEqual(true, set.contains(35));
    try expectEqual(true, set.contains(40));
    try expectEqual(false, set.contains(23));
    try expectEqual(false, set.contains(80));

    try set.delete(15);
    try set.delete(50);
    try expectEqual(5, set.size);

    try expectEqual(true, set.contains(40));
    try expectEqual(true, set.contains(20));
    try expectEqual(false, set.contains(50));
    try expectEqual(false, set.contains(15));
}

test "Set.empty()" {
    var set = Set(i32, cmp.default_cmp).init(test_allocator);
    defer set.deinit();
    try set.insert(10);
    try set.insert(5);
    try set.insert(8);
    try set.insert(20);
    try expectEqual(false, set.empty());

    try set.delete(10);
    try set.delete(20);
    try expectEqual(false, set.empty());

    try set.delete(5);
    try set.delete(8);
    try expectEqual(true, set.empty());
}

test "Set.format()" {
    var set = Set(i32, cmp.default_cmp).init(test_allocator);
    defer set.deinit();
    try set.insert(10);
    try set.insert(5);
    try set.insert(6);
    try set.insert(15);
    try set.insert(13);
    try set.insert(20);

    var set_string = try std.fmt.allocPrint(
        test_allocator,
        "{s}",
        .{set},
    );
    try expectEqual(true, std.mem.eql(u8, set_string, "[ 5 6 10 13 15 20 ]"));
    test_allocator.free(set_string);

    try set.delete(10);
    try set.delete(5);
    try set.delete(6);
    try set.delete(15);
    try set.delete(13);
    try set.delete(20);

    set_string = try std.fmt.allocPrint(
        test_allocator,
        "{s}",
        .{set},
    );
    try expectEqual(true, std.mem.eql(u8, set_string, "[ ]"));
    test_allocator.free(set_string);
}
