const std = @import("std");
const raylib = @import("raylib.zig/build.zig");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "shooting-tower",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    raylib.addTo(b, exe, target.query, optimize, .{});
    b.installArtifact(exe);

    const run = b.step("run", "shooting tower");
    const run_cmd = b.addRunArtifact(exe);
    run.dependOn(&run_cmd.step);
}
