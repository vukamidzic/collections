const std = @import("std");
const expectEqual = std.testing.expectEqual;
const expectError = std.testing.expectError;

pub const CmpResult = enum { LT, GT, EQ };
pub const CmpErr = error{NotEqualTypes};

pub fn default_cmp(obj1: anytype, obj2: anytype) CmpErr!CmpResult {
    const T = @TypeOf(obj1);
    const U = @TypeOf(obj2);

    if (T != U) return CmpErr.NotEqualTypes;

    const T_info = @typeInfo(T);
    const U_info = @typeInfo(U);

    // comparing primitive types
    if (T_info != .Struct and U_info != .Struct) {
        if (obj1 < obj2) {
            return CmpResult.LT;
        } else if (obj1 > obj2) {
            return CmpResult.GT;
        } else {
            return CmpResult.EQ;
        }
    } else {
        const fields_count = T_info.Struct.fields.len;

        inline for (0..fields_count) |idx| {
            const field_name = T_info.Struct.fields[idx].name;

            const v1 = @field(obj1, field_name);
            const v2 = @field(obj2, field_name);

            const rec_res = default_cmp(v1, v2) catch |err| return err;
            if (rec_res != CmpResult.EQ) return rec_res;
        }
    }

    return CmpResult.EQ;
}

test "default_cmp() with primitives" {
    var a: i32 = 10;
    var b: i32 = 10;
    try expectEqual(CmpResult.EQ, default_cmp(a, b));

    a = 15;
    b = 5;
    try expectEqual(CmpResult.GT, default_cmp(a, b));

    a = 5;
    b = 15;
    try expectEqual(CmpResult.LT, default_cmp(a, b));

    const c: f64 = 69.0;
    try expectError(CmpErr.NotEqualTypes, default_cmp(a, c));
    try expectEqual(CmpResult.LT, default_cmp(a, @as(i32, c)));
}

test "default_cmp() with structs" {
    const A = struct { field1: i32, field2: f64 };
    const B = struct { field1: i32, field2: f64 };

    const a = A{ .field1 = 10, .field2 = 10.0 };
    const b = B{ .field1 = 10, .field2 = -10.0 };

    try expectError(CmpErr.NotEqualTypes, default_cmp(a, b));

    const c = A{ .field1 = 5, .field2 = 15.0 };
    try expectEqual(CmpResult.GT, default_cmp(a, c));

    const d = B{ .field1 = 10, .field2 = -5.0 };
    try expectEqual(CmpResult.LT, default_cmp(b, d));
}
