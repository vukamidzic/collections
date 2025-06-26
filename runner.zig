const std = @import("std");
const builtin = @import("builtin");

pub fn main() !void {
    for (builtin.test_functions) |t| {
        const prefix = "tests.test.";
        const pretty_name = if (std.mem.startsWith(u8, t.name, prefix))
            t.name[prefix.len..]
        else
            t.name;

        t.func() catch {
            std.log.err("[{s}] \xE2\x86\x92 \x1b[91m\xE2\x9C\x97\x1b[0m", .{pretty_name});
            continue;
        };
        std.log.info("[{s}] \xE2\x86\x92 \x1b[92m\xE2\x9C\x93\x1b[0m", .{pretty_name});
    }
}
