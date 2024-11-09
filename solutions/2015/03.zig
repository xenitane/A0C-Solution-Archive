const std = @import("std");

const print = std.debug.print;

fn get_input(ac: std.mem.Allocator) ![]const u8 {
    const args = try std.process.argsAlloc(ac);
    defer std.process.argsFree(ac, args);
    const file_name = try std.fmt.allocPrint(ac, "inputs/{s}/{s}.txt", .{ args[1], args[2] });
    defer ac.free(file_name);
    var input_file = try std.fs.cwd().openFile(file_name, .{ .mode = .read_only });
    defer input_file.close();
    const file_size = (try input_file.stat()).size;
    const buffer = try ac.alloc(u8, file_size);
    try input_file.reader().readNoEof(buffer);
    return buffer;
}

pub fn main() !void {
    var GPA = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = GPA.allocator();
    defer _ = GPA.deinit();
    const input = try get_input(gpa);
    defer gpa.free(input);
    try solve(input, gpa);
}

fn solve(input: []const u8, gpalloc: std.mem.Allocator) !void {
    var s1 = HashSet([2]i32).init(gpalloc);
    defer s1.deinit();
    var s2 = HashSet([2]i32).init(gpalloc);
    defer s2.deinit();
    try s1.put(.{ 0, 0 }, 0);
    try s2.put(.{ 0, 0 }, 0);

    var p_0: [2]i32 = .{ 0, 0 };
    var p_1: [2][2]i32 = .{ .{ 0, 0 }, .{ 0, 0 } };

    var flg: u1 = 1;

    for (input) |chr| {
        switch (chr) {
            '^' => {
                p_0[1] += 1;
                p_1[flg][1] += 1;
            },
            '>' => {
                p_0[0] += 1;
                p_1[flg][0] += 1;
            },
            '<' => {
                p_0[0] -= 1;
                p_1[flg][0] -= 1;
            },
            'v' => {
                p_0[1] -= 1;
                p_1[flg][1] -= 1;
            },
            else => continue,
        }
        try s1.put(p_0, 0);
        try s2.put(p_1[flg], 0);
        flg = 1 - flg;
    }

    const res_1 = s1.count();
    const res_2 = s2.count();
    print("part 1: {d}\npart 2: {d}", .{ res_1, res_2 });
}

fn HashSet(comptime T: type) type {
    return std.AutoHashMap(T, u0);
}
