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

const ModType = enum {
    RESET,
    TURN_ON,
    TURN_OFF,
    TOGGLE,
};

const State = struct {
    op: ModType = .RESET,
    start_x: u10 = 0,
    start_y: u10 = 0,
    end_x: u10 = 0,
    end_y: u10 = 0,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa_allocator = gpa.allocator();
    defer _ = gpa.deinit();
    const input = try get_input(gpa_allocator);
    defer gpa_allocator.free(input);

    var res_1: u64 = 0;
    var res_2: i64 = 0;

    res_1 = 0;
    res_2 = 0;

    var masks: [1001]u1000 = undefined;
    masks[0] = 0;
    for (1..1001) |i| masks[i] = (masks[i - 1] << 1) + 1;

    var grid: [1000]u1000 = undefined;
    for (0..grid.len) |i| grid[i] = 0;
    var brightness: [1000000]u16 = undefined;
    for (0..1000000) |i| {
        brightness[i] = 0;
    }
    var state: State = .{};

    const n = input.len;
    var idx: usize = 0;
    while (idx < n) : (idx += 1) {
        if (input[idx + 1] == 'u') {
            if (input[idx + 6] == 'n') {
                state.op = .TURN_ON;
                idx += 8;
            } else {
                state.op = .TURN_OFF;
                idx += 9;
            }
        } else {
            state.op = .TOGGLE;
            idx += 7;
        }
        while (input[idx] != ',') : (idx += 1) {
            state.start_x = state.start_x * 10 + (input[idx] - '0');
        }
        idx += 1;
        while (input[idx] != ' ') : (idx += 1) {
            state.start_y = state.start_y * 10 + (input[idx] - '0');
        }
        idx += 9;
        while (input[idx] != ',') : (idx += 1) {
            state.end_x = state.end_x * 10 + (input[idx] - '0');
        }
        idx += 1;
        while (input[idx] != '\n') : (idx += 1) {
            state.end_y = state.end_y * 10 + (input[idx] - '0');
        }

        var mask: u1000 = masks[state.end_x + 1] - masks[state.start_x];
        if (state.op == .TURN_OFF) mask = masks[1000] ^ mask;

        for (state.start_y..(state.end_y + 1)) |i| {
            switch (state.op) {
                .TURN_ON => {
                    grid[i] |= mask;
                },
                .TURN_OFF => {
                    grid[i] &= mask;
                },
                .TOGGLE => {
                    grid[i] ^= mask;
                },
                .RESET => {
                    unreachable;
                },
            }
        }
        for (state.start_x..(state.end_x + 1)) |i| {
            for (state.start_y..(state.end_y + 1)) |j| {
                var jdx: usize = i;
                jdx *= 1000;
                jdx += j;
                brightness[jdx] = switch (state.op) {
                    .TURN_ON => brightness[jdx] + 1,
                    .TURN_OFF => if (brightness[jdx] > 0) brightness[jdx] - 1 else 0,
                    .TOGGLE => brightness[jdx] + 2,
                    .RESET => unreachable,
                };
            }
        }
        state = .{};
    }

    for (0..grid.len) |i| {
        res_1 += @popCount(grid[i]);
    }
    for (0..1000000) |i| {
        res_2 += brightness[i];
    }

    print("part 1: {d}\npart 2: {d}", .{ res_1, res_2 });
}
