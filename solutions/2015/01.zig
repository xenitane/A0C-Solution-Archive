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
    solve(input);
}

fn solve(input: []const u8) void {
    var res_1: i64 = 0;
    var res_2: u64 = 0;
    for (input, 1..) |ii, idx| {
        if (ii == '(') {
            res_1 += 1;
            continue;
        }
        if (ii == ')') res_1 -= 1;
        if (res_2 == 0 and res_1 < 0) res_2 = idx;
    }
    print("part 1: {d}\npart 2: {d}", .{ res_1, res_2 });
}
