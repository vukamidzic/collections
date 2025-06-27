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

        fn hash(buckets_len: u64, key: anytype) !u64 {
            const info = @typeInfo(@TypeOf(key));
            switch (info) {
                .int, .comptime_int => {
                    if (info.int.signedness == .signed) {
                        const U = std.meta.Int(.unsigned, info.int.bits);
                        const ukey: U = @bitCast(key);
                        var h = std.hash.int(@as(u64, ukey));
                        h %= @as(u64, buckets_len);
                        return h;
                    } else {
                        var h = std.hash.int(@as(u64, key));
                        h %= @as(u64, buckets_len);
                        return h;
                    }
                },
                .float, .comptime_float => {
                    const ukey: u64 = if (K == f32) @bitCast(@as(f64, key)) else @bitCast(key);
                    var h = std.hash.int(ukey);
                    h %= @as(u64, buckets_len);
                    return h;
                },
                .array => {
                    if (info.array.child == u8) {
                        var h = std.hash.Wyhash.hash(0, key);
                        h %= @as(u64, buckets_len);
                        return h;
                    }
                },
                .pointer => {
                    if (info.pointer.child == u8) {
                        var h = std.hash.Wyhash.hash(0, key);
                        h %= @as(u64, buckets_len);
                        return h;
                    }
                },
                .@"struct" => {
                    const fields = info.@"struct".fields;
                    var total_h: u64 = 0;
                    inline for (fields) |field| {
                        const value = @field(key, field.name);
                        var tmp_h = try hash(buckets_len, value);
                        tmp_h %= @as(u64, buckets_len);
                        total_h ^= tmp_h;
                    }
                    return total_h;
                },
                else => {
                    return error.NotImplemented;
                },
            }
        }

        fn get_bucket(self: *Self, key: K) !*std.ArrayList(Pair) {
            const h = try hash(self.buckets.len, key);
            return &self.buckets[h];
        }

        pub fn put(self: *Self, key: K, value: V) !void {
            var bucket = try self.get_bucket(key);

            // TODO: extract comp_fn assignment into separate function!!!
            const cmp_fn: ?fn (K, K) bool = comptime blk: {
                const info = @typeInfo(K);
                switch (info) {
                    .int, .comptime_int, .float, .comptime_float => break :blk struct {
                        fn cmp(a: K, b: K) bool {
                            return a == b;
                        }
                    }.cmp,
                    .array => break :blk struct {
                        fn cmp(a: K, b: K) bool {
                            return std.mem.eql(info.array.child, a, b);
                        }
                    }.cmp,
                    .pointer => break :blk struct {
                        fn cmp(a: K, b: K) bool {
                            return std.mem.eql(info.pointer.child, a, b);
                        }
                    }.cmp,
                    .@"struct" => break :blk struct {
                        fn cmp(a: K, b: K) bool {
                            return std.meta.eql(a, b);
                        }
                    }.cmp,
                    else => break :blk null,
                }
            };

            if (cmp_fn != null) {
                for (bucket.items) |*pair| {
                    if (cmp_fn.?(pair.key, key)) {
                        pair.value = value;
                        return;
                    }
                }
                try bucket.append(.{ .key = key, .value = value });
            } else return error.NotImplemented;
        }

        pub fn erase(self: *Self, key: K) !void {
            var bucket = try self.get_bucket(key);

            const cmp_fn: ?fn (K, K) bool = comptime blk: {
                const info = @typeInfo(K);
                switch (info) {
                    .int, .comptime_int, .float, .comptime_float => break :blk struct {
                        fn cmp(a: K, b: K) bool {
                            return a == b;
                        }
                    }.cmp,
                    .array => break :blk struct {
                        fn cmp(a: K, b: K) bool {
                            return std.mem.eql(info.array.child, a, b);
                        }
                    }.cmp,
                    .pointer => break :blk struct {
                        fn cmp(a: K, b: K) bool {
                            return std.mem.eql(info.pointer.child, a, b);
                        }
                    }.cmp,
                    .@"struct" => break :blk struct {
                        fn cmp(a: K, b: K) bool {
                            return std.meta.eql(a, b);
                        }
                    }.cmp,
                    else => break :blk null,
                }
            };

            if (cmp_fn != null) {
                if (bucket.items.len > 0) {
                    var idx: usize = 0;
                    for (bucket.items) |*pair| {
                        if (cmp_fn.?(pair.key, key)) {
                            break;
                        }
                        idx += 1;
                    }

                    if (idx < bucket.items.len) _ = bucket.swapRemove(idx);
                }
            } else return error.NotImplemented;
        }

        pub fn find(self: *Self, key: K) !?V {
            const bucket = try self.get_bucket(key);
            const cmp_fn: ?fn (K, K) bool = comptime blk: {
                const info = @typeInfo(K);
                switch (info) {
                    .int, .comptime_int, .float, .comptime_float => break :blk struct {
                        fn cmp(a: K, b: K) bool {
                            return a == b;
                        }
                    }.cmp,
                    .array => break :blk struct {
                        fn cmp(a: K, b: K) bool {
                            return std.mem.eql(info.array.child, a, b);
                        }
                    }.cmp,
                    .pointer => break :blk struct {
                        fn cmp(a: K, b: K) bool {
                            return std.mem.eql(info.pointer.child, a, b);
                        }
                    }.cmp,
                    .@"struct" => break :blk struct {
                        fn cmp(a: K, b: K) bool {
                            return std.meta.eql(a, b);
                        }
                    }.cmp,
                    else => break :blk null,
                }
            };

            if (cmp_fn != null) {
                for (bucket.items) |pair| {
                    if (cmp_fn.?(pair.key, key)) {
                        return pair.value;
                    }
                }
                return null;
            } else return error.NotImplemented;
        }

        pub fn contains(self: *Self, key: K) !bool {
            const bucket = try self.get_bucket(key);
            const cmp_fn: ?fn (K, K) bool = comptime blk: {
                const info = @typeInfo(K);
                switch (info) {
                    .int, .comptime_int, .float, .comptime_float => break :blk struct {
                        fn cmp(a: K, b: K) bool {
                            return a == b;
                        }
                    }.cmp,
                    .array => break :blk struct {
                        fn cmp(a: K, b: K) bool {
                            return std.mem.eql(info.array.child, a, b);
                        }
                    }.cmp,
                    .pointer => break :blk struct {
                        fn cmp(a: K, b: K) bool {
                            return std.mem.eql(info.pointer.child, a, b);
                        }
                    }.cmp,
                    .@"struct" => break :blk struct {
                        fn cmp(a: K, b: K) bool {
                            return std.meta.eql(a, b);
                        }
                    }.cmp,
                    else => break :blk null,
                }
            };

            if (cmp_fn != null) {
                for (bucket.items) |pair| {
                    if (cmp_fn.?(pair.key, key)) {
                        return true;
                    }
                }
                return false;
            } else return error.NotImplemented;
        }

        pub fn format(self: Self, comptime fmt: []const u8, opts: std.fmt.FormatOptions, writer: anytype) !void {
            _ = fmt;
            _ = opts;

            for (self.buckets) |bucket| {
                try writer.print("[", .{});
                for (bucket.items) |pair| {
                    const key_info = @typeInfo(@TypeOf(pair.key));
                    switch (key_info) {
                        .array, .pointer => {
                            try writer.print("{{ {s} : {any} }}", .{ pair.key, pair.value });
                        },
                        else => {
                            try writer.print("{{ {any} : {any} }}", .{ pair.key, pair.value });
                        },
                    }
                }
                try writer.print("]\n", .{});
            }
        }
    };
}
