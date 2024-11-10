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

    //
    var containers = std.ArrayList(u8).init(ac);
    defer containers.deinit();
    var idx: usize = 0;
    while (idx < input.len) : (idx += 1) {
        var size: u8 = 0;
        while (input[idx] != '\n') : (idx += 1) size = size * 10 + input[idx] - 48;
        try containers.append(size);
    }

    var dp = try ac.alloc([EGGNOG_QTY + 1]Aaaaa, containers.items.len + 1);
    defer ac.free(dp);

    for (dp) |*row| {
        inline for (0..(EGGNOG_QTY + 1)) |c| row.*[c] = Aaaaa.init(ac);
    }
    defer for (dp) |*row| {
        inline for (0..(EGGNOG_QTY + 1)) |c| row.*[c].deinit();
    };

    try dp[containers.items.len][EGGNOG_QTY].append(.{ 0, 1 });

    _ = try make_dp(dp, containers, 0, 0);

    for (dp[0][0].items) |qq| res_1 += qq[1];
    res_2 = dp[0][0].items[0][1];

    print("part 1: {}\npart 2: {}", .{ res_1, res_2 });
}

fn make_dp(dp: [][EGGNOG_QTY + 1]Aaaaa, containers: std.ArrayList(u8), idx: usize, en: u8) !bool {
    if (idx == containers.items.len) return en == EGGNOG_QTY;
    if (en > EGGNOG_QTY) return false;
    if (dp[idx][en].items.len != 0) return true;

    const len0 = if (try make_dp(dp, containers, idx + 1, en)) dp[idx + 1][en].items.len else 0;
    const len1 = if (try make_dp(dp, containers, idx + 1, en + containers.items[idx])) dp[idx + 1][en + containers.items[idx]].items.len else 0;

    var ii: usize = 0;
    var jj: usize = 0;

    while (ii < len0 and jj < len1) {
        const aa = dp[idx + 1][en].items[ii];
        const bb = dp[idx + 1][en + containers.items[idx]].items[jj];
        switch (order(aa[0], bb[0] + 1)) {
            .lt => {
                try dp[idx][en].append(aa);
                ii += 1;
            },
            .gt => {
                try dp[idx][en].append(.{ bb[0] + 1, bb[1] });
                jj += 1;
            },
            .eq => {
                try dp[idx][en].append(.{ aa[0], aa[1] + bb[1] });
                ii += 1;
                jj += 1;
            },
        }
    }
    while (ii < len0) : (ii += 1) try dp[idx][en].append(dp[idx + 1][en].items[ii]);
    while (jj < len1) : (jj += 1) {
        const aa = dp[idx + 1][en + containers.items[idx]].items[jj];
        try dp[idx][en].append(.{ aa[0] + 1, aa[1] });
    }

    return dp[idx][en].items.len != 0;
}

const Aaaaa = std.ArrayList([2]u32);
const order = std.math.order;
const EGGNOG_QTY: u8 = 150;
