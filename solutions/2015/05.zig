const std = @import("std");

const print = std.debug.print;

fn get_input(allocator: std.mem.Allocator) ![]const u8 {
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    const file_name = try std.fmt.allocPrint(allocator, "inputs/{s}/{s}.txt", .{ args[1], args[2] });
    defer allocator.free(file_name);
    var input_file = try std.fs.cwd().openFile(file_name, .{ .mode = .read_only });
    defer input_file.close();
    const file_size = (try input_file.stat()).size;
    const buffer = try allocator.alloc(u8, file_size);
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
    var res_1: u64 = 0;
    var res_2: u64 = 0;

    var idx: usize = 0;
    while (idx < input.len) : (idx += 1) {
        var last: u8 = 0;
        var second_last: u8 = 0;

        var vowel_count: usize = 0;
        var pair: bool = false;
        var no_invalid_pairs: bool = true;

        var xyx: bool = false;
        var pair_frq: [676]bool = [_]bool{false} ** 676;
        var non_overlaping_repeating_pair: bool = false;
        var last_pair: i16 = -1;

        while (input[idx] != '\n') : (idx += 1) {
            vowel_count += switch (input[idx]) {
                'a', 'e', 'i', 'o', 'u' => 1,
                else => 0,
            };

            if (last == input[idx]) pair = true;

            if (last == 'a' and input[idx] == 'b') {
                no_invalid_pairs = false;
            } else if (last == 'c' and input[idx] == 'd') {
                no_invalid_pairs = false;
            } else if (last == 'p' and input[idx] == 'q') {
                no_invalid_pairs = false;
            } else if (last == 'x' and input[idx] == 'y') {
                no_invalid_pairs = false;
            }

            if (second_last == input[idx]) xyx = true;

            if (!non_overlaping_repeating_pair and last > 0) {
                var cur_pair: i16 = last - 'a';
                cur_pair *= 26;
                cur_pair += input[idx] - 'a';
                if (last_pair != cur_pair) {
                    const jdx: u16 = @bitCast(cur_pair);
                    if (pair_frq[jdx]) non_overlaping_repeating_pair = true;
                    pair_frq[jdx] = true;
                    last_pair = cur_pair;
                } else {
                    last_pair = -1;
                }
            }

            second_last = last;
            last = input[idx];
        }
        if (vowel_count > 2 and pair and no_invalid_pairs) res_1 += 1;
        if (xyx and non_overlaping_repeating_pair) res_2 += 1;
    }

    print("part 1: {d}\npart 2: {d}", .{ res_1, res_2 });
}
