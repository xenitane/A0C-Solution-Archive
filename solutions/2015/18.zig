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

    var state0: State = undefined;
    var state1: State = undefined;
    for (0..100) |i| {
        for (0..100) |j| {
            state0[i][j] = switch (input[i * 101 + j]) {
                '.' => false,
                '#' => true,
                else => unreachable,
            };
            state1[i][j] = state0[i][j];
        }
    }

    for (0..100) |_| {
        var new_state0: State = undefined;
        var new_state1: State = undefined;
        for (0..100) |i| {
            for (0..100) |j| {
                const active_neighbors0 = count_active_neighbors(&state0, i, j);
                new_state0[i][j] = active_neighbors0 == 3 or (active_neighbors0 == 2 and state0[i][j]);

                const active_neighbors1 = count_active_neighbors(&state1, i, j);
                new_state1[i][j] = active_neighbors1 == 3 or (active_neighbors1 == 2 and state1[i][j]);
            }
        }
        for (0..100) |i| {
            for (0..100) |j| {
                state0[i][j] = new_state0[i][j];
                state1[i][j] = new_state1[i][j];
            }
        }
        state1[0][0] = true;
        state1[0][99] = true;
        state1[99][0] = true;
        state1[99][99] = true;
    }

    for (0..100) |i| {
        for (0..100) |j| {
            if (state0[i][j]) res_1 += 1;
            if (state1[i][j]) res_2 += 1;
        }
    }

    print("part 1: {}\npart 2: {}", .{ res_1, res_2 });
}

const State = [100][100]bool;

fn count_active_neighbors(s: *const State, x: usize, y: usize) u8 {
    const start_x = if (x == 0) 0 else x - 1;
    const start_y = if (y == 0) 0 else y - 1;
    const end_x = if (x == 99) 100 else x + 2;
    const end_y = if (y == 99) 100 else y + 2;

    var res: u8 = 0;
    for (start_x..end_x) |i| {
        for (start_y..end_y) |j| {
            if (s.*[i][j]) res += 1;
        }
    }
    if (s.*[x][y]) res -= 1;
    return res;
}
