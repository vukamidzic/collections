const std = @import("std");

pub fn HashMap(comptime K: type, comptime V: type) type {
    return struct {
        const Self = @This();
        const Pair = struct { key: K, value: V };
        const Bucket = std.ArrayList(Pair);

        buckets: [16]Bucket, // TODO: make this dynamic
        allocator: std.mem.Allocator,

        pub fn init(allocator: std.mem.Allocator) Self {
            var buckets: [16]Bucket = undefined;
            for (&buckets) |*bucket| {
                bucket.* = Bucket.init(allocator);
            }

            return Self{
                .buckets = buckets,
                .allocator = allocator,
            };
        }

        pub fn deinit(self: *Self) void {
            for (self.buckets) |bucket| {
                bucket.deinit();
            }
        }

        pub fn put(self: *Self, key: K, value: V) !void {
            if (@typeInfo(K) == .int) {
                var h = std.hash.int(@as(u64, key));
                h = h % @as(u64, self.buckets.len);
                var bucket = &self.buckets[h];

                for (bucket.items) |*pair| {
                    if (pair.key == key) {
                        pair.value = value;
                        return;
                    }
                }

                try bucket.append(.{ .key = key, .value = value });
            } else {
                return error.NotImplemented;
            }
        }

        pub fn format(self: Self, comptime fmt: []const u8, opts: std.fmt.FormatOptions, writer: anytype) !void {
            _ = fmt;
            _ = opts;

            for (self.buckets) |bucket| {
                try writer.print("[", .{});
                for (bucket.items) |pair| {
                    try writer.print("{{ {any} : {any} }}", .{ pair.key, pair.value });
                }
                try writer.print("]\n", .{});
            }
        }
    };
}
