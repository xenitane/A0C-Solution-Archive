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
    var res_1: u64 = undefined;
    var res_2: u64 = undefined;

    res_1 = 0;
    res_2 = 0;

    var pairDistance = std.AutoHashMap([2]u8, u32).init(ac);
    defer pairDistance.deinit();
    var city_count: u8 = 0;
    {
        var idx: usize = 0;
        var cityIdx = std.StringHashMap(u8).init(ac);
        defer cityIdx.deinit();
        while (idx < input.len) : (idx += 1) {
            var city0: []const u8 = undefined;
            var city1: []const u8 = undefined;
            var distance: u32 = 0;
            var jdx = idx;
            while (input[jdx] != ' ') : (jdx += 1) {}
            city0 = input[idx..jdx];
            idx = jdx + 4;
            jdx = idx;
            while (input[jdx] != ' ') : (jdx += 1) {}
            city1 = input[idx..jdx];
            idx = jdx + 3;
            while (input[idx] != '\n') : (idx += 1) distance = distance * 10 + input[idx] - 48;
            const cdx0 = blk: {
                const city_gop = try cityIdx.getOrPut(city0);
                if (!city_gop.found_existing) {
                    city_gop.value_ptr.* = city_count;
                    city_count += 1;
                }
                break :blk city_gop.value_ptr.*;
            };
            const cdx1 = blk: {
                const city_gop = try cityIdx.getOrPut(city1);
                if (!city_gop.found_existing) {
                    city_gop.value_ptr.* = city_count;
                    city_count += 1;
                }
                break :blk city_gop.value_ptr.*;
            };
            try pairDistance.put(.{ @min(cdx0, cdx1), @max(cdx0, cdx1) }, distance);
        }
    }
    const perm = try ac.alloc(u8, city_count);
    defer ac.free(perm);
    for (0..city_count) |i| perm[i] = @truncate(i);
    res_1 = calculate_path_length(perm, pairDistance);
    res_2 = res_1;
    while (next_perm(perm)) {
        const new_path_length = calculate_path_length(perm, pairDistance);
        res_1 = @min(res_1, new_path_length);
        res_2 = @max(res_2, new_path_length);
    }

    print("part 1: {d}\npart 2: {d}", .{ res_1, res_2 });
}

fn calculate_path_length(perm: []const u8, dist: std.AutoHashMap([2]u8, u32)) u64 {
    var res: u64 = 0;
    for (1..perm.len) |i| res += dist.get(.{ @min(perm[i], perm[i - 1]), @max(perm[i], perm[i - 1]) }) orelse unreachable;
    return res;
}

fn next_perm(perm: []u8) bool {
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
