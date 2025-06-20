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

        pub fn empty(self: *Self) bool {
            for (self.buckets) |bucket| {
                if (bucket.items.len != 0) return false;
            }

            return true;
        }

        fn get_bucket(self: *Self, key: K) !*std.ArrayList(Pair) {
            const info = @typeInfo(K);
            switch (info) {
                .int, .comptime_int => {
                    if (info.int.signedness == .signed) {
                        const U = std.meta.Int(.unsigned, info.int.bits);
                        const ukey: U = @bitCast(key);
                        var h = std.hash.int(@as(u64, ukey));
                        h = h % @as(u64, self.buckets.len);
                        return &self.buckets[h];
                    } else {
                        var h = std.hash.int(@as(u64, key));
                        h = h % @as(u64, self.buckets.len);
                        return &self.buckets[h];
                    }
                },
                .float, .comptime_float => {
                    const ukey: u64 = if (K == f32) @bitCast(@as(f64, key)) else @bitCast(key);
                    var h = std.hash.int(ukey);
                    h = h % @as(u64, self.buckets.len);
                    return &self.buckets[h];
                },
                else => {
                    return error.NotImplemented;
                },
            }
        }

        pub fn put(self: *Self, key: K, value: V) !void {
            var bucket = self.get_bucket(key) catch |err| return err;
            for (bucket.items) |*pair| {
                if (pair.key == key) {
                    pair.value = value;
                    return;
                }
            }

            try bucket.append(.{ .key = key, .value = value });
        }

        pub fn erase(self: *Self, key: K) !void {
            var bucket = self.get_bucket(key) catch |err| return err;

            var idx: usize = 0;
            for (bucket.items) |*pair| {
                if (pair.key == key) {
                    break;
                }
                idx += 1;
            }

            if (bucket.items.len > 0 and idx < bucket.items.len) _ = bucket.swapRemove(idx);
        }

        pub fn find(self: *Self, key: K) ?V {
            const bucket = self.get_bucket(key) catch |err| return err;
            for (bucket.items) |pair| {
                if (pair.key == key) {
                    return pair.value;
                }
            }
            return null;
        }

        pub fn contains(self: *Self, key: K) bool {
            const bucket = self.get_bucket(key) catch |err| return err;
            for (bucket.items) |pair| {
                if (pair.key == key) {
                    return true;
                }
            }
            return false;
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
