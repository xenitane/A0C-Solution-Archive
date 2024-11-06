const std = @import("std");

const print = std.debug.print;
const md5 = std.crypto.hash.Md5.hash;

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

    var bin: []u8 = try gpa_allocator.alloc(u8, input.len + 12);
    defer gpa_allocator.free(bin);
    var out: [16]u8 = undefined;
    @memset(bin, 0);
    for (input, 0..) |ii, i| bin[i] = ii;
    for (1..10000000) |i| {
        if (res_1 > 0 and res_2 > 0) break;
        const aa = (try std.fmt.bufPrint(bin[(input.len - 1)..], "{d}", .{i})).len + input.len - 1;
        md5(bin[0..aa], &out, .{});
        if (out[0] == 0 and out[1] == 0) {
            if (out[2] < 16 and res_1 == 0) res_1 = i;
            if (out[2] == 0 and res_2 == 0) res_2 = i;
        }
    }

    print("part 1: {d}\npart 2: {d}", .{ res_1, res_2 });
}
