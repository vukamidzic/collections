const std = @import("std");
const builtin = @import("builtin");

pub fn main() !void {
    const total_num: u32 = @intCast(builtin.test_functions.len);
    var failed_num: u32 = 0;

    for (builtin.test_functions) |t| {
        t.func() catch {
            std.debug.print("\x1b[1;47m\x1b[1;30m TEST \x1b[0m [{s}] \x1b[1;41m\x1b[97m FAIL \x1b[0m\n", .{t.name});
            failed_num += 1;
            continue;
        };
        std.debug.print("\x1b[1;47m\x1b[1;30m TEST \x1b[0m [{s}] \x1b[1;42m\x1b[97m PASS \x1b[0m\n", .{t.name});
    }

    const passed_num: u32 = total_num - failed_num;

    std.debug.print("\n\x1b[1;43m\x1b[97m TOTAL \x1b[0m\x1b[47m\x1b[30m[ {d} ]\x1b[0m\n", .{total_num});
    std.debug.print("\x1b[1;42m\x1b[97m PASSED \x1b[0m\x1b[47m\x1b[30m[ {d} ]\x1b[0m\n", .{passed_num});
    std.debug.print("\x1b[1;41m\x1b[97m FAILED \x1b[0m\x1b[47m\x1b[30m[ {d} ]\x1b[0m\n", .{failed_num});
}
