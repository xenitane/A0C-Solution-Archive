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
    return buffer[0..file_size];
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa_allocator = gpa.allocator();
    defer _ = gpa.deinit();
    const input = try get_input(gpa_allocator);
    defer gpa_allocator.free(input);

    var res_1: u64 = 0;
    var res_2: u64 = 0;

    res_2 = 0;

    var p0: u8 = 0;
    var p1: u8 = 0;

    var vowel_count: usize = 0;
    var same_pair: bool = false;
    var all_valid_pair: bool = true;

    var xyx: bool = false;
    var last_pair: u16 = 0;
    var pair_frq: [676]usize = undefined;
    for (0..676) |i| pair_frq[i] = 0;

    for (input) |chr| {
        switch (chr) {
            '\n' => {
                if (vowel_count > 2 and same_pair and all_valid_pair) res_1 += 1;
                if (xyx and any_gt(&pair_frq, 1)) {
                    res_2 += 1;
                }
                p0 = 0;
                p1 = 0;
                vowel_count = 0;
                same_pair = false;
                all_valid_pair = true;

                xyx = false;
                last_pair = 0;
                for (0..676) |i| pair_frq[i] = 0;
            },
            else => {
                switch (chr) {
                    'a', 'e', 'i', 'o', 'u' => {
                        vowel_count += 1;
                    },
                    else => {},
                }
                if (p0 == chr) same_pair = true;
                if ((p0 == 'a' and chr == 'b') or (p0 == 'c' and chr == 'd') or (p0 == 'p' and chr == 'q') or (p0 == 'x' and chr == 'y')) {
                    all_valid_pair = false;
                }

                if (p0 > 0) {
                    var cur_pr: u16 = 0;
                    cur_pr += p0 - 'a';
                    cur_pr *= 26;
                    cur_pr += chr - 'a';
                    if (last_pair != cur_pr) {
                        pair_frq[cur_pr] += 1;
                        last_pair = cur_pr;
                    } else {
                        last_pair = 0;
                    }
                }
                if (p1 == chr) xyx = true;

                p1 = p0;
                p0 = chr;
            },
        }
    }

    print("part 1: {d}\npart 2: {d}", .{ res_1, res_2 });
}

fn any_gt(arr: *[676]usize, el: usize) bool {
    for (0..arr.len) |i| if (arr[i] > el) return true;
    return false;
}
