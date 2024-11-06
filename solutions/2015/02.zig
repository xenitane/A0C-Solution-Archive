const std = @import("std");

const print = std.debug.print;
const swap = std.mem.swap;

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

    var a: u32 = 0;
    var b: u32 = 0;
    var c: u32 = 0;
    for (input) |char| {
        switch (char) {
            '\n' => {
                if (a > b) swap(u32, &a, &b);
                if (a > c) swap(u32, &a, &c);
                if (b > c) swap(u32, &b, &c);
                const paper = 2 * c * (a + b) + (3 * a * b);
                const ribbon = 2 * (a + b) + (a * b * c);
                res_1 += paper;
                res_2 += ribbon;
                a = 0;
                b = 0;
                c = 0;
            },
            'x' => {
                if (a == 0) {
                    a = c;
                } else {
                    b = c;
                }
                c = 0;
            },
            else => {
                c = c * 10 + (char - '0');
            },
        }
    }

    print("part 1: {d}\npart 2: {d}", .{ res_1, res_2 });
}
