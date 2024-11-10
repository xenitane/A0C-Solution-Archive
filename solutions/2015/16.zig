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
    var main_properties = std.StringHashMap(struct { u8, std.math.Order }).init(ac);
    defer main_properties.deinit();
    try main_properties.put("children", .{ 3, .eq });
    try main_properties.put("cats", .{ 7, .lt });
    try main_properties.put("samoyeds", .{ 2, .eq });
    try main_properties.put("pomeranians", .{ 3, .gt });
    try main_properties.put("akitas", .{ 0, .eq });
    try main_properties.put("vizslas", .{ 0, .eq });
    try main_properties.put("goldfish", .{ 5, .gt });
    try main_properties.put("trees", .{ 3, .lt });
    try main_properties.put("cars", .{ 2, .eq });
    try main_properties.put("perfumes", .{ 1, .eq });

    var res_1: u64 = undefined;
    var res_2: u64 = undefined;

    var idx: usize = 0;
    var count: u16 = 1;
    while (idx < input.len) : (idx += 1) {
        var matches0: bool = true;
        var matches1: bool = true;
        while (input[idx] != ':') : (idx += 1) {}
        while (input[idx] != '\n') {
            idx += 2;
            var jdx = idx;
            while (input[jdx] != ':') : (jdx += 1) {}
            const data_point = input[idx..jdx];
            idx = jdx + 2;
            var qty: u8 = 0;
            while (std.ascii.isDigit(input[idx])) : (idx += 1) qty = qty * 10 + input[idx] - 48;
            const expected_qty = main_properties.get(data_point) orelse unreachable;
            if (qty != expected_qty[0]) matches0 = false;
            if (std.math.order(expected_qty[0], qty) != expected_qty[1]) matches1 = false;
        }
        if (matches0) res_1 = count;
        if (matches1) res_2 = count;
        count += 1;
    }

    print("part 1: {}\npart 2: {}", .{ res_1, res_2 });
}
