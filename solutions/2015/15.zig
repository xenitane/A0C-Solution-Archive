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

    var ing_array_list = std.ArrayList(Ingredient).init(ac);
    defer ing_array_list.deinit();

    var idx: usize = 0;
    while (idx < input.len) : (idx += 1) {
        var capacity: i64 = undefined;
        var durability: i64 = undefined;
        var flavor: i64 = undefined;
        var texture: i64 = undefined;
        var calories: i64 = undefined;
        while (input[idx] != ':') : (idx += 1) {}
        for (0..5) |_| {
            idx += 2;
            var jdx = idx;
            while (input[jdx] != ' ') : (jdx += 1) {}
            const filed_name = input[idx..jdx];
            idx = jdx + 1;

            var val: i64 = 0;
            var sign: bool = false;
            if (input[idx] == '-') {
                sign = true;
                idx += 1;
            }
            while (std.ascii.isDigit(input[idx])) : (idx += 1) val = val * 10 + input[idx] - 48;
            if (sign) val *= -1;
            if (std.mem.eql(u8, filed_name, "capacity")) {
                capacity = val;
            } else if (std.mem.eql(u8, filed_name, "durability")) {
                durability = val;
            } else if (std.mem.eql(u8, filed_name, "flavor")) {
                flavor = val;
            } else if (std.mem.eql(u8, filed_name, "texture")) {
                texture = val;
            } else if (std.mem.eql(u8, filed_name, "calories")) {
                calories = val;
            }
        }
        try ing_array_list.append(.{
            .capacity = capacity,
            .durability = durability,
            .flavor = flavor,
            .texture = texture,
            .calories = calories,
        });
    }
    get_max_score(&ing_array_list, &res_1, &res_2, 0, 0, .{});

    print("part 1: {d}\npart 2: {d}", .{ res_1, res_2 });
}

fn get_max_score(lst: *const std.ArrayList(Ingredient), res0: *u64, res1: *u64, idx: usize, tsps: u64, rec: Ingredient) void {
    if (idx == lst.items.len) {
        if (tsps == TARGET) {
            const t_res: u64 = @as(u64, @max(0, rec.capacity)) * @as(u64, @max(0, rec.durability)) * @as(u64, @max(0, rec.flavor)) * @as(u64, @max(0, rec.texture));
            res0.* = @max(res0.*, t_res);
            if (rec.calories == 500) res1.* = @max(res1.*, t_res);
        }
        return;
    }
    const req_tsps: u64 = TARGET - tsps;
    var new_rec: Ingredient = rec;
    for (0..(req_tsps + 1)) |i| {
        get_max_score(lst, res0, res1, idx + 1, tsps + i, new_rec);
        new_rec.capacity += lst.items[idx].capacity;
        new_rec.durability += lst.items[idx].durability;
        new_rec.flavor += lst.items[idx].flavor;
        new_rec.texture += lst.items[idx].texture;
        new_rec.calories += lst.items[idx].calories;
    }
}

const TARGET: u64 = 100;

const Ingredient = struct {
    capacity: i64 = 0,
    durability: i64 = 0,
    flavor: i64 = 0,
    texture: i64 = 0,
    calories: i64 = 0,
};
