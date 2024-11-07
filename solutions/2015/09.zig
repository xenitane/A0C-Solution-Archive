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

    var res_1: u64 = undefined;
    var res_2: u64 = undefined;

    res_1 = 0;
    res_2 = 0;

    var cityIdx = std.StringHashMap(u8).init(gpa_allocator);
    defer cityIdx.deinit();
    var pairDistance = std.AutoHashMap(u16, u32).init(gpa_allocator);
    defer pairDistance.deinit();

    const n = input.len;
    var idx: usize = 0;
    var city_count: u8 = 0;
    while (idx < n) : (idx += 1) {
        var city0: []const u8 = undefined;
        var city1: []const u8 = undefined;
        var distance: u32 = undefined;
        var jdx = idx;
        while (input[jdx] != ' ') : (jdx += 1) {}
        city0 = input[idx..jdx];
        idx = jdx + 4;
        jdx = idx;
        while (input[jdx] != ' ') : (jdx += 1) {}
        city1 = input[idx..jdx];
        idx = jdx + 3;
        while (input[jdx] != '\n') : (jdx += 1) {}
        distance = try std.fmt.parseUnsigned(u32, input[idx..jdx], 10);
        idx = jdx;
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
        const pair_id = min_append(cdx0, cdx1);
        try pairDistance.put(pair_id, distance);
    }
    const perm = try gpa_allocator.alloc(u8, city_count);
    defer gpa_allocator.free(perm);
    perm[0] = 0;
    for (1..city_count) |i| perm[i] = perm[i - 1] + 1;
    res_1 = calculate_path_length(perm, pairDistance);
    res_2 = res_1;
    while (next_perm(perm)) {
        const new_path_length = calculate_path_length(perm, pairDistance);
        if (new_path_length < res_1) res_1 = new_path_length;
        if (new_path_length > res_2) res_2 = new_path_length;
    }

    print("part 1: {d}\npart 2: {d}", .{ res_1, res_2 });
}

fn calculate_path_length(perm: []const u8, dist: std.AutoHashMap(u16, u32)) u64 {
    var res: u64 = 0;
    for (1..perm.len) |i| res += dist.get(min_append(perm[i - 1], perm[i])) orelse unreachable;
    return res;
}

fn min_append(a: u8, b: u8) u16 {
    var res: u16 = a ^ b;
    res ^= if (a > b) a else b;
    res <<= 8;
    res |= a ^ b;
    res ^= if (a > b) b else a;
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
