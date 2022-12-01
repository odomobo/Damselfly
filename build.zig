const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("damselfly", "src/main.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.install();
    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_tests = b.addTest("src/damselfly.zig");
    exe_tests.setTarget(target);
    exe_tests.setBuildMode(mode);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&exe_tests.step);

    register_xxx(b, target, mode);
    register_perft(b, target, mode);
}

fn register_xxx(b: *std.build.Builder, target: std.zig.CrossTarget, mode: std.builtin.Mode) void {
    const exe = b.addExecutable("xxx", "test/xxx.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.addPackagePath("damselfly", "src/damselfly.zig");

    const install_exe = b.addInstallArtifact(exe);

    const install_step = b.step("xxx", "Build adhoc test application");
    install_step.dependOn(&install_exe.step);

    const run_cmd = exe.run();
    run_cmd.step.dependOn(&install_exe.step);
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("xxx-run", "Run adhoc test application");
    run_step.dependOn(&run_cmd.step);
}

fn register_perft(b: *std.build.Builder, target: std.zig.CrossTarget, mode: std.builtin.Mode) void {
    const exe = b.addExecutable("perft", "test/perft.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.addPackagePath("damselfly", "src/damselfly.zig");

    const install_exe = b.addInstallArtifact(exe);

    const install_step = b.step("perft", "Build perft test application");
    install_step.dependOn(&install_exe.step);

    const run_cmd = exe.run();
    run_cmd.step.dependOn(&install_exe.step);
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("perft-run", "Run perft test application");
    run_step.dependOn(&run_cmd.step);
}