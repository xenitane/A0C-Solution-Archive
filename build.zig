const std = @import("std");
const builtin = @import("builtin");

const Build = std.Build;
const CompileStep = Build.CompileStep;
const Step = Build.Step;
const Child = std.process.Child;

const assert = std.debug.assert;
const join = std.fs.path.join;
const print = std.debug.print;

comptime {
    const req_ver = "0.13.0";
    const cur_ver = builtin.zig_version;
    const min_ver = std.SemanticVersion.parse(req_ver) catch unreachable;
    if (cur_ver.order(min_ver) == .lt) {
        const error_msg =
            \\Sorry, it looks like your version of zig is too old. :-(
            \\
            \\AoC requires at least
            \\
            \\{}
            \\
            \\or higher.
            \\
            \\Please download an appropriate version from
            \\
            \\https://ziglang.org/download/
            \\
            \\
        ;
        @compileError(std.fmt.comptimePrint(error_msg, .{min_ver}));
    }
}

pub const RunMode = enum {
    RUN,
    TEST,
};

pub const Solution = struct {
    main_file: []const u8,
    year: usize,
    day: usize,
    mode: RunMode = .RUN,
};

pub const logo =
    \\
    \\      \__    __/
    \\      /_/ /\ \_\
    \\     __ \ \/ / __
    \\     \_\_\/\/_/_/
    \\ __/\___\_\/_/___/\__
    \\   \/ __/_/\_\__ \/
    \\     /_/ /\/\ \_\
    \\      __/ /\ \__
    \\      \_\ \/ /_/
    \\      /        \
    \\
    \\
;

pub fn build(b: *Build) !void {
    use_color_escapes = false;
    if (std.io.getStdErr().supportsAnsiEscapeCodes()) {
        use_color_escapes = true;
    } else if (builtin.os.tag == .windows) {
        const w32 = struct {
            const WINAPI = std.os.windows.WINAPI;
            const DWORD = std.os.windows.DWORD;
            const ENABLE_VIRTUAL_TERMINAL_PROCESSING = 0x0004;
            const STD_ERROR_HANDLE: DWORD = @bitCast(@as(i32, -12));
            extern "kernel32" fn GetStdHandle(id: DWORD) callconv(WINAPI) ?*anyopaque;
            extern "kernel32" fn GetConsoleMode(console: ?*anyopaque, out_mode: *DWORD) callconv(WINAPI) u32;
            extern "kernel32" fn SetConsoleMode(console: ?*anyopaque, mode: DWORD) callconv(WINAPI) u32;
        };
        const handle = w32.GetStdHandle(w32.STD_ERROR_HANDLE);
        var mode: w32.DWORD = 0;
        if (w32.GetConsoleMode(handle, &mode) != 0) {
            mode |= w32.ENABLE_VIRTUAL_TERMINAL_PROCESSING;
            use_color_escapes = w32.SetConsoleMode(handle, mode) != 0;
        }
    }

    if (use_color_escapes) {
        red_text = "\x1b[31m";
        red_bold_text = "\x1b[31;1m";
        red_dim_text = "\x1b[31;2m";
        green_text = "\x1b[32m";
        bold_text = "\x1b[1m";
        reset_text = "\x1b[0m";
    }

    b.top_level_steps = .{};

    const year: usize = b.option(usize, "year", "Select Yeay") orelse 0;
    const day: usize = b.option(usize, "day", "Select Day") orelse 0;

    const header_step = PrintStep.create(b, logo);
    const work_path = "solutions";

    const req_solution = get_solution(b, work_path, year, day) catch {
        print("File `{s}/{d:0>4}/{d:0>2}.zig` does not exist.\n", .{ work_path, year, day });
        std.process.exit(2);
    };

    const aoc_step = b.step("aoc", b.fmt("Running the solution for {d:0>4}-{d:0>2}", .{ year, day }));
    b.default_step = aoc_step;
    aoc_step.dependOn(&header_step.step);

    const verify_step = AoCStep.create(b, req_solution, work_path);
    verify_step.step.dependOn(&header_step.step);

    aoc_step.dependOn(&verify_step.step);

    const aoc_test_step = b.step("aoc-test", b.fmt("Testing the solution for {d:0>4}-{d:0>2}", .{ year, day }));
    aoc_test_step.dependOn(&header_step.step);

    const req_test: Solution = .{
        .mode = .TEST,
        .main_file = req_solution.main_file,
        .year = req_solution.year,
        .day = req_solution.day,
    };
    const verify_test_step = AoCStep.create(b, req_test, work_path);
    verify_test_step.step.dependOn(&header_step.step);
    aoc_test_step.dependOn(&verify_test_step.step);
}

var use_color_escapes = false;
var red_text: []const u8 = "";
var red_bold_text: []const u8 = "";
var red_dim_text: []const u8 = "";
var green_text: []const u8 = "";
var bold_text: []const u8 = "";
var reset_text: []const u8 = "";

fn get_solution(b: *Build, work_path: []const u8, y: usize, d: usize) !Solution {
    if (y == 0 or d == 0) return .{ .year = 0, .day = 0, .main_file = "null" };

    try std.fs.cwd().access(b.fmt("{s}/{d:0>4}/{d:0>2}.zig", .{ work_path, y, d }), .{});

    return .{
        .year = y,
        .day = d,
        .main_file = b.fmt("{d:0>4}/{d:0>2}.zig", .{ y, d }),
    };
}

fn resetLine() void {
    if (use_color_escapes) print("{s}", .{"\x1b[2K\r"});
}

const PrintStep = struct {
    step: Step,
    message: []const u8,

    pub fn create(owner: *Build, message: []const u8) *PrintStep {
        const self = owner.allocator.create(PrintStep) catch @panic("OOM");
        self.* = .{
            .step = Step.init(.{
                .id = .custom,
                .name = "print",
                .owner = owner,
                .makeFn = make,
            }),
            .message = message,
        };

        return self;
    }

    fn make(step: *Step, _: std.Progress.Node) !void {
        const self: *PrintStep = @alignCast(@fieldParentPtr("step", step));
        print("{s}", .{self.message});
    }
};

const AoCStep = struct {
    step: Step,
    solution: Solution,
    work_path: []const u8,

    pub fn create(b: *Build, sol: Solution, work_path: []const u8) *AoCStep {
        const self = b.allocator.create(AoCStep) catch @panic("OOM");
        self.* = .{
            .step = Step.init(.{
                .id = .custom,
                .name = sol.main_file,
                .owner = b,
                .makeFn = make,
            }),
            .solution = sol,
            .work_path = work_path,
        };
        return self;
    }
    fn make(step: *Step, prog_node: std.Progress.Node) !void {
        const self: *AoCStep = @alignCast(@fieldParentPtr("step", step));

        if (self.solution.year == 0 or self.solution.day == 0) {
            self.help();
            return;
        }

        const exe_path = self.compile(prog_node) catch {
            self.printErrors();
            self.help();
            std.process.exit(2);
        };

        self.run(exe_path.?, prog_node) catch {
            self.printErrors();
            self.help();
            std.process.exit(2);
        };

        self.printErrors();
    }

    fn run(self: *AoCStep, exe_path: []const u8, _: std.Progress.Node) !void {
        resetLine();
        print("Executing: {s}/{s}\n", .{ self.work_path, self.solution.main_file });

        const b = self.step.owner;

        const max_output_bytes: usize = 0x100000;

        const result = Child.run(.{
            .allocator = b.allocator,
            .argv = &.{
                exe_path,
                if (self.solution.mode == .RUN) b.fmt("{d:0>4}", .{self.solution.year}) else "test",
                if (self.solution.mode == .RUN) b.fmt("{d:0>2}", .{self.solution.day}) else "test",
            },
            .cwd = b.build_root.path.?,
            .cwd_dir = b.build_root.handle,
            .max_output_bytes = max_output_bytes,
        }) catch |err| {
            return self.step.fail("unable to spawn {s}: {s}", .{ exe_path, @errorName(err) });
        };

        return self.save_output(result);
    }

    fn save_output(self: *AoCStep, result: Child.RunResult) !void {
        switch (result.term) {
            .Exited => |code| {
                if (code != 0) {
                    return self.step.fail("{s} exited with error code {d} (expected {})", .{
                        self.solution.main_file, code, 0,
                    });
                }
            },
            else => {
                return self.step.fail("{s} terminated unexpectedly\n{s}{s}{s}\n", .{
                    self.solution.main_file, red_text, result.stderr, reset_text,
                });
            },
        }

        const raw_output = result.stderr;
        print("--------------------------------------------------\n", .{});
        print("{s}\n", .{raw_output});
        print("--------------------------------------------------\n", .{});
        if (self.solution.mode == .RUN) {
            const file = try self.get_output_file();
            defer file.close();
            try file.writeAll(raw_output);
        }
    }

    fn get_output_file(self: *AoCStep) !std.fs.File {
        const b = self.step.owner;
        const cwd = std.fs.cwd();
        var dd = cwd.openDir("outputs", .{}) catch |err| switch (err) {
            std.fs.Dir.OpenError.FileNotFound => blk: {
                try cwd.makeDir("outputs");
                break :blk try cwd.openDir("outputs", .{});
            },
            else => {
                return err;
            },
        };
        defer dd.close();
        var de = dd.openDir(b.fmt("{d:0>4}", .{self.solution.year}), .{}) catch |err| switch (err) {
            std.fs.Dir.OpenError.FileNotFound => blk: {
                try dd.makeDir(b.fmt("{d:0>4}", .{self.solution.year}));
                break :blk try dd.openDir(b.fmt("{d:0>4}", .{self.solution.year}), .{});
            },
            else => {
                return err;
            },
        };
        defer de.close();
        return de.createFile(b.fmt("{d:0>2}.txt", .{self.solution.day}), .{});
    }

    fn compile(self: *AoCStep, prog_node: std.Progress.Node) !?[]const u8 {
        print("Compiling {s}/{s}\n", .{ self.work_path, self.solution.main_file });

        const b = self.step.owner;
        const solution_path = self.solution.main_file;
        const path = join(b.allocator, &.{ self.work_path, solution_path }) catch @panic("OOM");

        var zig_args = std.ArrayList([]const u8).init(b.allocator);
        defer zig_args.deinit();

        zig_args.append(b.graph.zig_exe) catch @panic("OOM");

        zig_args.append("build-exe") catch @panic("OOM");

        zig_args.append(b.pathFromRoot(path)) catch @panic("OOM");

        zig_args.append("--listen=-") catch @panic("OOM");

        return try self.step.evalZigProcess(zig_args.items, prog_node);
    }

    fn help(self: *AoCStep) void {
        const b = self.step.owner;
        const path = self.solution.main_file;
        const year = self.solution.year;
        const day = self.solution.day;

        if (year == 0 or day == 0) {
            print(
                \\To run a solution of year `y`, day `d` run the following command:
                \\zig build aoc{s} -Dyear=y -Dday=d
                \\With the code and input present.
                \\
            , .{if (self.solution.mode == .TEST) "-test" else ""});
            return;
        }
        const cmd = b.fmt("zig build aoc{s} -Dyear={d} -Dday={d}", .{ if (self.solution.mode == .TEST) "-test" else "", year, day });

        print("\n{s}Update solutions/{s} and run '{s}' again.{s}\n", .{
            red_bold_text, path, cmd, reset_text,
        });
    }

    fn printErrors(self: *AoCStep) void {
        resetLine();

        if (self.step.result_error_msgs.items.len > 0) {
            for (self.step.result_error_msgs.items) |msg| {
                print("{s}error: {s}{s}{s}{s}\n", .{ red_bold_text, reset_text, red_dim_text, msg, reset_text });
            }
        }

        const ttyconf: std.io.tty.Config = if (use_color_escapes)
            .escape_codes
        else
            .no_color;
        if (self.step.result_error_bundle.errorMessageCount() > 0) {
            self.step.result_error_bundle.renderToStdErr(.{ .ttyconf = ttyconf });
        }
    }
};
