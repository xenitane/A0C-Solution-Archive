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
    var res_2: i64 = 0;

    const result = json_parse_and_sum(input);

    res_1 = result[0];
    res_2 = result[1];

    print("part 1: {d}\npart 2: {d}", .{ res_1, res_2 });
}

fn json_parse_and_sum(json: []const u8) [2]i64 {
    var idx: usize = 0;
    return switch (json[0]) {
        '{' => json_parse_object(json, &idx),
        '[' => json_parse_array(json, &idx),
        else => unreachable,
    };
}

fn json_parse_object(json: []const u8, pos: *usize) [2]i64 {
    pos.* += 1;
    var res = [2]i64{ 0, 0 };
    var ignore = false;
    while (json[pos.*] != '}') {
        _ = json_parse_string(json, pos);
        pos.* += 1;
        switch (json[pos.*]) {
            '{' => {
                const t_res = json_parse_object(json, pos);
                res[0] += t_res[0];
                res[1] += t_res[1];
            },
            '[' => {
                const t_res = json_parse_array(json, pos);
                res[0] += t_res[0];
                res[1] += t_res[1];
            },
            '"' => {
                if (json_parse_string(json, pos)) ignore = true;
            },
            else => {
                const t_res = json_parse_number(json, pos);
                res[0] += t_res;
                res[1] += t_res;
            },
        }
        if (json[pos.*] == ',') pos.* += 1;
    }
    pos.* += 1;
    if (ignore) res[1] = 0;
    return res;
}
fn json_parse_array(json: []const u8, pos: *usize) [2]i64 {
    pos.* += 1;
    var res = [2]i64{ 0, 0 };
    while (json[pos.*] != ']') {
        switch (json[pos.*]) {
            '{' => {
                const t_res = json_parse_object(json, pos);
                res[0] += t_res[0];
                res[1] += t_res[1];
            },
            '[' => {
                const t_res = json_parse_array(json, pos);
                res[0] += t_res[0];
                res[1] += t_res[1];
            },
            '"' => {
                _ = json_parse_string(json, pos);
            },
            else => {
                const t_res = json_parse_number(json, pos);
                res[0] += t_res;
                res[1] += t_res;
            },
        }
        if (json[pos.*] == ',') pos.* += 1;
    }
    pos.* += 1;
    return res;
}
fn json_parse_number(json: []const u8, pos: *usize) i64 {
    const mul: usize = if (json[pos.*] == '-') 1 else 0;
    var result: i64 = 0;
    var k = pos.* + mul;
    while (std.ascii.isDigit(json[k])) : (k += 1) result = result * 10 + json[k] - 48;
    pos.* = k;
    return switch (mul) {
        0 => result,
        1 => -result,
        else => unreachable,
    };
}
fn json_parse_string(json: []const u8, pos: *usize) bool {
    var k = pos.* + 1;
    while (json[k] != '"') : (k += 1) {}
    k += 1;
    std.mem.swap(usize, &k, pos);
    return pos.* - k == 5 and std.mem.eql(u8, json[k..(pos.*)], "\"red\"");
}
