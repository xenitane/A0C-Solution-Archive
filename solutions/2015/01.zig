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

    var res_1: i64 = 0;
    var res_2: u64 = 0;
    for (input, 1..) |c, i| {
        switch (c) {
            '(' => {
                res_1 += 1;
            },
            ')' => {
                res_1 -= 1;
                if (res_1 < 0 and res_2 == 0) res_2 = i;
            },
            else => {},
        }
    }
    print("part 1: {d}\npart 2: {d}", .{ res_1, res_2 });
}
