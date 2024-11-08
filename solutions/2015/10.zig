const std = @import("std");

const print = std.debug.print;

const BUF_SIZE: usize = 1 << 24;

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
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa_allocator = gpa.allocator();
    defer _ = gpa.deinit();
    const input = try get_input(gpa_allocator);
    defer gpa_allocator.free(input);

    var res_1: u64 = undefined;
    var res_2: u64 = undefined;

    res_1 = 0;
    res_2 = 0;

    const rslt_buf = try gpa_allocator.alloc(u8, BUF_SIZE);
    defer gpa_allocator.free(rslt_buf);
    const temp_buf = try gpa_allocator.alloc(u8, BUF_SIZE);
    defer gpa_allocator.free(temp_buf);
    @memset(rslt_buf, 0);
    @memset(temp_buf, 0);
    var n = input.len;

    for (0..(n - 1)) |i| rslt_buf[i] = input[i];

    try update_rle(rslt_buf, temp_buf, &n, 40);

    res_1 = n - 1;

    try update_rle(rslt_buf, temp_buf, &n, 10);

    res_2 = n - 1;

    print("part 1: {d}\npart 2: {d}", .{ res_1, res_2 });
}

fn update_rle(rslt_buf: []u8, temp_buf: []u8, n: *usize, q: usize) !void {
    for (0..q) |_| {
        var last: u8 = rslt_buf[0];
        var len: usize = 0;
        var p: usize = 0;
        for (0..(n.*)) |i| {
            if (rslt_buf[i] != last) {
                p += (try std.fmt.bufPrint(temp_buf[p..], "{d}{c}", .{ len, last })).len;
                last = rslt_buf[i];
                len = 0;
            }
            len += 1;
        }
        n.* = p + 1;
        for (0..p) |i| rslt_buf[i] = temp_buf[i];
        rslt_buf[p] = 0;
    }
}
