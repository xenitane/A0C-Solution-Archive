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

fn solve(input: []const u8, ac: std.mem.Allocator) !void {
    var res_1: u64 = 0;
    var res_2: u64 = 0;

    const input_len = input.len - 1;

    var buf: []u8 = try ac.alloc(u8, input_len + 12);
    defer ac.free(buf);
    @memset(buf, 0);
    for (0..input_len) |i| buf[i] = input[i];

    var md5_hash_digest: [16]u8 = undefined;

    for (0..MAXN) |i| {
        if (res_1 > 0 and res_2 > 0) break;
        const buf_len = input_len + (try std.fmt.bufPrint(buf[input_len..], "{d}", .{i + 1})).len;
        md5(buf[0..buf_len], &md5_hash_digest, .{});
        if (md5_hash_digest[0] == 0 and md5_hash_digest[1] == 0) {
            if (res_1 == 0 and md5_hash_digest[2] < 16) res_1 = i + 1;
            if (res_2 == 0 and md5_hash_digest[2] == 0) res_2 = i + 1;
        }
    }

    print("part 1: {d}\npart 2: {d}", .{ res_1, res_2 });
}

const md5 = std.crypto.hash.Md5.hash;
const MAXN = 100000000;
