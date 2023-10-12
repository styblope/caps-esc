const std = @import("std");

pub fn build(b: *std.Build) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const optimize = b.standardOptimizeOption(.{.preferred_optimize_mode=.ReleaseSmall});

    const exe = b.addExecutable(.{
        .name = "caps-esc",
        .root_source_file = .{.path = "src/main.zig"},
        .target = target,
        .optimize = optimize,
    });
    exe.linkLibC();
    exe.linkSystemLibrary("evdev");
    exe.addIncludePath(.{.path="/usr/include/libevdev-1.0"});
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe); 
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
