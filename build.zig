const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    _ = b.addModule("collections", .{
        .root_source_file = b.path("src/mod.zig"),
        .target = target,
        .optimize = optimize,
    });

    const tests = b.addTest(.{
        .root_source_file = b.path("tests.zig"),
        .test_runner = b.path("./test_runner.zig"),
        .target = target,
        .optimize = optimize,
    });

    const test_step = b.step("test", "Run library unit tests");

    const run_tests = b.addRunArtifact(tests);
    test_step.dependOn(&run_tests.step);
}
