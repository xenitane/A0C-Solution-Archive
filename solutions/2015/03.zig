const std = @import("std");

const print = std.debug.print;
const swap = std.mem.swap;

fn HashSet(comptime T: type) type {
    return std.AutoHashMap(T, u0);
}

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

    var s1 = HashSet(u64).init(gpa_allocator);
    defer s1.deinit();
    var s2 = HashSet(u64).init(gpa_allocator);
    defer s2.deinit();
    try s1.put(0, 0);
    try s2.put(0, 0);

    var p_0: struct { i32, i32 } = .{ 0, 0 };

    var p_1_0: struct { i32, i32 } = .{ 0, 0 };
    var p_1_1: struct { i32, i32 } = .{ 0, 0 };

    var flg: bool = false;

    for (input) |chr| {
        switch (chr) {
            '^' => {
                p_0[1] += 1;
                if (flg) {
                    p_1_1[1] += 1;
                } else {
                    p_1_0[1] += 1;
                }
            },
            '>' => {
                p_0[0] += 1;
                if (flg) {
                    p_1_1[0] += 1;
                } else {
                    p_1_0[0] += 1;
                }
            },
            '<' => {
                p_0[0] -= 1;
                if (flg) {
                    p_1_1[0] -= 1;
                } else {
                    p_1_0[0] -= 1;
                }
            },
            'v' => {
                p_0[1] -= 1;
                if (flg) {
                    p_1_1[1] -= 1;
                } else {
                    p_1_0[1] -= 1;
                }
            },
            else => {},
        }
        try s1.put(get_bin_val(p_0), 0);
        if (flg) {
            try s2.put(get_bin_val(p_1_1), 0);
        } else {
            try s2.put(get_bin_val(p_1_0), 0);
        }
        flg = !flg;
    }

    const res_1 = s1.count();
    const res_2 = s2.count();

    print("part 1: {d}\npart 2: {d}", .{ res_1, res_2 });
}

fn get_bin_val(data: struct { i32, i32 }) u64 {
    var res: u64 = 0;
    var aa: u32 = undefined;
    aa = @bitCast(data[0]);
    res |= aa;
    res <<= 32;
    aa = @bitCast(data[1]);
    res |= aa;
    return res;
}
