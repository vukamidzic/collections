const std = @import("std");
const expectEqual = std.testing.expectEqual;

pub fn Set(comptime T: type) type {
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

        fn __deinit(root: ?*SetNode, allocator: std.mem.Allocator) void {
            if (root) |node| {
                __deinit(node.left, allocator);
                __deinit(node.right, allocator);
                allocator.destroy(node);
            }
        }

        pub fn deinit(self: *Self) void {
            __deinit(self.root, self.allocator);
        }

        fn __insert(root: ?*SetNode, value: T, allocator: std.mem.Allocator) !?*SetNode {
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
                root.?.left = try __insert(root.?.left, value, allocator);
            } else {
                root.?.right = try __insert(root.?.right, value, allocator);
            }

            return root;
        }

        pub fn insert(self: *Self, value: T) !void {
            self.root = try __insert(self.root, value, self.allocator);
            self.size += 1;
        }
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
