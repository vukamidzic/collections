const std = @import("std");
const expectEqual = std.testing.expectEqual;
const expectError = std.testing.expectError;

const CmpResult = enum { LT, GT, EQ };
const CmpErr = error{ NotEqualTypes, NotEqualSizes, NotEqualFieldNames };

pub fn default_cmp(obj1: anytype, obj2: anytype) CmpErr!CmpResult {
    const T = @TypeOf(obj1);
    const U = @TypeOf(obj2);

    if (T != U) return CmpErr.NotEqualTypes;

    const T_info = @typeInfo(T);
    const U_info = @typeInfo(U);

    if (T_info != .Struct and U_info != .Struct) {
        if (obj1 < obj2) {
            return CmpResult.LT;
        } else if (obj1 > obj2) {
            return CmpResult.GT;
        } else {
            return CmpResult.EQ;
        }
    } else {
        const T_fields_count = T_info.Struct.fields.len;
        const U_fields_count = U_info.Struct.fields.len;
        if (T_fields_count != U_fields_count) return CmpErr.NotEqualSizes;

        inline for (0..T_fields_count) |idx| {
            const T_field_name = T_info.Struct.fields[idx].name;
            const U_field_name = U_info.Struct.fields[idx].name;
            if (!std.mem.eql(u8, T_field_name, U_field_name)) return CmpErr.NotEqualFieldNames;

            const v1 = @field(obj1, T_field_name);
            const v2 = @field(obj2, U_field_name);

            const rec_res = default_cmp(v1, v2) catch |err| {
                return err;
            };
            if (rec_res != CmpResult.EQ) return rec_res;
        }
    }

    return CmpResult.EQ;
}

test "default_cmp()_primitives" {
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

test "default_cmp()_structs" {
    const Vec2 = struct { x: f64, y: f64 };
    var a = Vec2{ .x = 10.0, .y = 10.0 };
    var b = Vec2{ .x = 10.0, .y = 15.0 };

    try expectEqual(CmpResult.LT, default_cmp(a, b));

    a = Vec2{ .x = 20.0, .y = 10.0 };
    b = Vec2{ .x = 15.0, .y = 10.0 };

    try expectEqual(CmpResult.GT, default_cmp(a, b));
}

//TODO: write more tests regarding the comparison between structs
