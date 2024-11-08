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

    var res_1: i64 = undefined;
    var res_2: i64 = undefined;

    var affinity = std.AutoHashMap([2]u8, i32).init(gpa_allocator);
    defer affinity.deinit();
    var cnt: u8 = 0;
    {
        var names_idx = std.StringHashMap(u8).init(gpa_allocator);
        defer names_idx.deinit();
        const n = input.len;
        var idx: usize = 0;
        while (idx < n) {
            var name0: []const u8 = undefined;
            var name1: []const u8 = undefined;
            var change: i32 = 0;
            var neg = false;
            var jdx = idx;
            while (input[jdx] != ' ') : (jdx += 1) {}
            name0 = input[idx..jdx];
            idx = jdx + 12;
            if (input[idx - 2] == 'e') neg = true;
            while (std.ascii.isDigit(input[idx])) : (idx += 1) change = change * 10 + input[idx] - 48;
            while (!std.ascii.isUpper(input[idx])) : (idx += 1) {}
            jdx = idx;
            while (input[jdx] != '.') : (jdx += 1) {}
            name1 = input[idx..jdx];
            idx = jdx + 2;
            const cdx0 = blk: {
                const cdx_gop = try names_idx.getOrPut(name0);
                if (!cdx_gop.found_existing) {
                    cdx_gop.value_ptr.* = cnt;
                    cnt += 1;
                }
                break :blk cdx_gop.value_ptr.*;
            };
            const cdx1 = blk: {
                const cdx_gop = try names_idx.getOrPut(name1);
                if (!cdx_gop.found_existing) {
                    cdx_gop.value_ptr.* = cnt;
                    cnt += 1;
                }
                break :blk cdx_gop.value_ptr.*;
            };
            if (neg) change *= -1;
            try affinity.put([2]u8{ cdx0, cdx1 }, change);
        }
    }

    const perm = try gpa_allocator.alloc(u8, cnt + 1);
    defer gpa_allocator.free(perm);
    perm[0] = 0;
    for (0..cnt) |i| {
        try affinity.put([2]u8{ perm[i], cnt }, 0);
        try affinity.put([2]u8{ cnt, perm[i] }, 0);
        perm[i + 1] = 1 + perm[i];
    }
    res_1 = calculate_happiness(perm[0..cnt], affinity);
    while (has_next(perm[0..cnt])) res_1 = @max(res_1, calculate_happiness(perm[0..cnt], affinity));
    std.mem.reverse(u8, perm[0..cnt]);
    res_2 = calculate_happiness(perm, affinity);
    while (has_next(perm)) res_2 = @max(res_2, calculate_happiness(perm, affinity));

    print("part 1: {d}\npart 2: {d}", .{ res_1, res_2 });
}

fn calculate_happiness(perm: []const u8, affinity: std.AutoHashMap([2]u8, i32)) i64 {
    const n = perm.len;
    var res: i64 = 0;
    for (0..n) |i| res += affinity.get([2]u8{ perm[i], perm[(i + 1) % n] }).? + affinity.get([2]u8{ perm[(i + 1) % n], perm[i] }).?;
    return res;
}

fn has_next(perm: []u8) bool {
    const n = perm.len;
    var i = n - 1;
    while (i > 0) : (i -= 1) if (perm[i - 1] < perm[i]) break;
    if (i == 0) return false;
    std.mem.reverse(u8, perm[i..n]);
    const p = i - 1;
    while (i < n) : (i += 1) if (perm[i] > perm[p]) break;
    std.mem.swap(u8, &perm[p], &perm[i]);
    return true;
}
