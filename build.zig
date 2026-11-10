const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const dep_btree_c = b.dependency("btree_c", .{
        .target = target,
        .optimize = optimize,
    });

    // The module carries the C sources, headers and libc, so importing it is enough.
    const module = b.addModule("btree_c_zig", .{
        .root_source_file = b.path("src/btree.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .sanitize_c = .off,
    });
    const translate_c = b.addTranslateC(.{
        .root_source_file = b.path("src/c.h"),
        .target = target,
        .optimize = optimize,
    });
    translate_c.addIncludePath(dep_btree_c.path(""));
    module.addImport("c", translate_c.createModule());

    module.addIncludePath(dep_btree_c.path(""));
    module.addCSourceFiles(.{
        .root = dep_btree_c.path(""),
        .files = &.{"btree.c"},
    });

    const btree_zig = b.addLibrary(.{
        .name = "btree_zig",
        .linkage = .static,
        .root_module = module,
    });
    btree_zig.installHeadersDirectory(dep_btree_c.path(""), "", .{
        .include_extensions = &.{"btree.h"},
    });
    b.installArtifact(btree_zig);

    const btree_zig_tests = b.addTest(.{
        .root_module = module,
    });

    const run_btree_zig_unit_tests = b.addRunArtifact(btree_zig_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_btree_zig_unit_tests.step);
}
