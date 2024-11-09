const std = @import("std");

const print = std.debug.print;

const BUF_SIZE: usize = 1 << 24;

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

fn solve(input: []const u8, ac: std.mem.Allocator) !void {
    var res_1: u64 = undefined;
    var res_2: u64 = undefined;

    res_1 = 0;
    res_2 = 0;

    var rslt_buf = try ac.alloc(u8, BUF_SIZE);
    defer ac.free(rslt_buf);
    var temp_buf = try ac.alloc(u8, BUF_SIZE);
    defer ac.free(temp_buf);
    @memset(rslt_buf, 0);
    @memset(temp_buf, 0);
    var length = input.len;

    for (0..length) |i| rslt_buf[i] = input[i];

    try update_rle(&rslt_buf, &temp_buf, &length, 40);

    res_1 = length - 1;

    try update_rle(&rslt_buf, &temp_buf, &length, 10);

    res_2 = length - 1;

    print("part 1: {d}\npart 2: {d}", .{ res_1, res_2 });
}

fn update_rle(rslt_buf: *[]u8, temp_buf: *[]u8, length: *usize, repeat_for: usize) !void {
    for (0..repeat_for) |_| {
        var last: u8 = rslt_buf.*[0];
        var count: usize = 0;
        var new_seq_len: usize = 0;
        for (0..length.*) |i| {
            if (rslt_buf.*[i] != last) {
                new_seq_len += (try std.fmt.bufPrint(temp_buf.*[new_seq_len..], "{d}{c}", .{ count, last })).len;
                last = rslt_buf.*[i];
                count = 0;
            }
            count += 1;
        }
        length.* = new_seq_len + 1;
        swap([]u8, temp_buf, rslt_buf);
        rslt_buf.*[new_seq_len] = 0;
    }
}

const swap = std.mem.swap;
