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

    solve(input);
}

fn solve(input: []const u8) void {
    var res_1: u64 = 0;
    var res_2: u64 = 0;

    res_1 = 0;
    res_2 = 0;

    var masks: [1001]u1000 = undefined;
    for (0..1001) |i| masks[i] = @truncate((@as(u1001, 1) << @truncate(i)) - 1);

    var grid: [1000]u1000 = [_]u1000{0} ** 1000;
    var brightness: [1000][1000]u16 = [_][1000]u16{[_]u16{0} ** 1000} ** 1000;

    var idx: usize = 0;
    while (idx < input.len) : (idx += 1) {
        var start_x: usize = 0;
        var start_y: usize = 0;
        var end_x: usize = 0;
        var end_y: usize = 0;
        var operation: OPERATION = .RESET;

        if (input[idx + 1] == 'u') {
            if (input[idx + 6] == 'n') {
                operation = .TURN_ON;
                idx += 8;
            } else {
                operation = .TURN_OFF;
                idx += 9;
            }
        } else {
            operation = .TOGGLE;
            idx += 7;
        }
        while (input[idx] != ',') : (idx += 1) start_x = start_x * 10 + (input[idx] - '0');
        idx += 1;
        while (input[idx] != ' ') : (idx += 1) start_y = start_y * 10 + (input[idx] - '0');
        idx += 9;
        while (input[idx] != ',') : (idx += 1) end_x = end_x * 10 + (input[idx] - '0');
        idx += 1;
        while (input[idx] != '\n') : (idx += 1) end_y = end_y * 10 + (input[idx] - '0');

        end_x += 1;
        end_y += 1;

        var mask: u1000 = masks[end_x] - masks[start_x];
        if (operation == .TURN_OFF) mask = masks[1000] ^ mask;

        for (start_y..end_y) |i| {
            switch (operation) {
                .TURN_ON => grid[i] |= mask,
                .TURN_OFF => grid[i] &= mask,
                .TOGGLE => grid[i] ^= mask,
                .RESET => unreachable,
            }
            for (start_x..end_x) |j| {
                brightness[i][j] = switch (operation) {
                    .TURN_ON => brightness[i][j] + 1,
                    .TURN_OFF => if (brightness[i][j] > 0) brightness[i][j] - 1 else 0,
                    .TOGGLE => brightness[i][j] + 2,
                    .RESET => unreachable,
                };
            }
        }
    }

    for (0..grid.len) |i| res_1 += @popCount(grid[i]);

    for (0..1000) |i| {
        for (0..1000) |j| res_2 += brightness[i][j];
    }
    print("part 1: {d}\npart 2: {d}", .{ res_1, res_2 });
}

const OPERATION = enum {
    RESET,
    TURN_ON,
    TURN_OFF,
    TOGGLE,
};
