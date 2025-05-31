const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    _ = b.addModule("collections", .{ .root_source_file = b.path("./src/root.zig") });

    const tests = b.addTest(.{
        .name = "collections_tests",
        .test_runner = .{
            .path = b.path("./runner.zig"),
            .mode = .simple,
        },
        .root_source_file = b.path("./src/tests.zig"),
        .target = target,
        .optimize = optimize,
    });

    const test_step = b.step("test", "Run library tests");
    const run_tests = b.addRunArtifact(tests);
    test_step.dependOn(&run_tests.step);
}
