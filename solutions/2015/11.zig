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
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa_allocator = gpa.allocator();
    defer _ = gpa.deinit();
    const input = try get_input(gpa_allocator);
    defer gpa_allocator.free(input);

    var res_1: [8]u8 = [_]u8{0} ** 8;
    var res_2: [8]u8 = [_]u8{0} ** 8;

    for (0..8) |i| res_1[i] = input[i];
    while (is_invalid_password(res_1)) : (next_password(&res_1)) {}
    for (0..8) |i| res_2[i] = res_1[i];
    next_password(&res_2);
    while (is_invalid_password(res_2)) : (next_password(&res_2)) {}

    //

    print("part 1: {s}\npart 2: {s}", .{ res_1, res_2 });
}

fn next_password(pass: *[8]u8) void {
    var carry: u8 = 1;
    for (1..8) |i| {
        pass[8 - i] += carry;
        carry = 0;
        if (pass[8 - i] > 'z') {
            carry = 1;
            pass[8 - i] -= 26;
        }
    }
}

fn is_invalid_password(pass: [8]u8) bool {
    var flag = false;
    for (1..6) |i| {
        if (pass[i] + 1 == pass[i + 1] and pass[i] + 2 == pass[i + 2]) {
            flag = true;
            break;
        }
    }

    if (!flag) return true;
    for (0..8) |i| {
        switch (pass[i]) {
            'i', 'l', 'o' => return true,
            else => {},
        }
    }
    var a: u8 = 0;
    var i: usize = 0;
    while (i < 7) : (i += 1) {
        if (pass[i] == pass[i + 1]) {
            if (a == 0) {
                a = pass[i];
                i += 1;
            } else if (pass[i] != a) {
                return false;
            } else {
                i += 1;
            }
        }
    }
    return true;
}
