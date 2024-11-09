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
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const gpalloc = gpa.allocator();
    defer _ = gpa.deinit();
    const input = try get_input(gpalloc);
    defer gpalloc.free(input);

    solve(input);
}

fn solve(input: []const u8) void {
    var res_1: u64 = 0;
    var res_2: u64 = 0;

    var state: [3]u64 = .{ 0, 0, 0 };

    var idx: usize = 0;
    while (idx < input.len) {
        for (0..state.len) |jj| {
            state[jj] = 0;
            while (std.ascii.isDigit(input[idx])) : (idx += 1) state[jj] = state[jj] * 10 + (input[idx] - 48);
            idx += 1;
        }
        if (state[0] > state[1]) swap(u64, &state[0], &state[1]);
        if (state[0] > state[2]) swap(u64, &state[0], &state[2]);
        if (state[1] > state[2]) swap(u64, &state[1], &state[2]);
        const paper = 2 * state[2] * (state[0] + state[1]) + 3 * state[0] * state[1];
        const ribbon = 2 * (state[0] + state[1]) + state[0] * state[1] * state[2];
        res_1 += paper;
        res_2 += ribbon;
    }

    print("part 1: {d}\npart 2: {d}", .{ res_1, res_2 });
}

const swap = std.mem.swap;
