const std = @import("std");
const ArrayList = std.ArrayList;
const expectEqual = std.testing.expectEqual;
const expectError = std.testing.expectError;

pub fn Set(comptime T: type) type {
    return struct {
        const Self = @This();
        pub const SetNode = struct {
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

            const m = @divFloor((l + r), 2);
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
            self.root = reorder(nodes.items, 0, @intCast(self.size - 1));
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

            if (value < root.?.value) {
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

        // TODO: implement Set.delete()
    };
}

test "Set.init()" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const set = Set(i32).init(allocator);
    try expectEqual(0, set.size);
}

test "Set.insert()" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var set = Set(i32).init(allocator);
    defer set.deinit();

    try set.insert(10);
    try set.insert(5);
    try set.insert(6);
    try set.insert(20);
    try expectEqual(4, set.size);
}
