const std = @import("std");
const Order = std.math.Order;

pub fn default_cmp(a: anytype, b: anytype) !Order {
    const T = @TypeOf(a);
    const U = @TypeOf(b);

    if (T != U) {
        return error.TypeMismatch;
    }

    const T_info = @typeInfo(T);
    const U_info = @typeInfo(U);

    if (T_info != .@"struct" and U_info != .@"struct") {
        return std.math.order(a, b);
    }

    if (T_info == .@"struct" and U_info == .@"struct") {
        const a_fields = T_info.@"struct".fields;
        const b_fields = U_info.@"struct".fields;

        inline for (0..a_fields.len) |i| {
            const a_value = @field(a, a_fields[i].name);
            const b_value = @field(b, b_fields[i].name);

            const ord = default_cmp(a_value, b_value) catch |err| {
                return err;
            };
            if (ord != Order.eq) {
                return ord;
            }
        }
    }

    return Order.eq;
}
