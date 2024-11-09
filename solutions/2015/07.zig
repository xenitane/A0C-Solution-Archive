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
    var res_1: u16 = 0;
    var res_2: u16 = 0;

    var wires = std.StringHashMap(u16).init(ac);
    defer wires.deinit();
    var gates = std.StringHashMap(Source).init(ac);
    defer gates.deinit();
    var gates_copy = std.StringHashMap(Source).init(ac);
    defer gates_copy.deinit();

    var idx: usize = 0;
    while (idx < input.len) : (idx += 1) {
        var src: Source = .{};
        if (std.ascii.isDigit(input[idx])) {
            src.left.num = 0;
            while (std.ascii.isDigit(input[idx])) : (idx += 1) src.left.num = src.left.num * 10 + (input[idx] - 48);
        } else {
            var jdx = idx;
            while (input[jdx] != ' ') : (jdx += 1) {}
            if (std.mem.eql(u8, input[idx..jdx], "NOT")) {
                src.op = .NOT;
            } else {
                src.left = Vals{ .idn = input[idx..jdx] };
            }
            idx = jdx;
        }
        idx += 1;
        if (input[idx] != '-') {
            if (std.ascii.isDigit(input[idx])) {
                src.left.num = 0;
                while (std.ascii.isDigit(input[idx])) : (idx += 1) src.left.num = src.left.num * 10 + (input[idx] - 48);
            } else {
                var jdx = idx;
                while (input[jdx] != ' ') : (jdx += 1) {}
                switch (input[idx]) {
                    'A' => src.op = .AND,
                    'O' => src.op = .OR,
                    'L' => src.op = .LSHIFT,
                    'R' => src.op = .RSHIFT,
                    else => src.left = Vals{ .idn = input[idx..jdx] },
                }
                idx = jdx;
            }
            idx += 1;
        }

        if (input[idx] != '-') {
            if (std.ascii.isDigit(input[idx])) {
                if (src.op == .LSHIFT or src.op == .RSHIFT) {
                    src.right = Vals{ .exp = 0 };
                    while (std.ascii.isDigit(input[idx])) : (idx += 1) src.right.exp = src.right.exp * 10 + @as(u4, @truncate(input[idx] - 48));
                } else {
                    src.right.num = 0;
                    while (std.ascii.isDigit(input[idx])) : (idx += 1) src.right.num = src.right.num * 10 + (input[idx] - 48);
                }
            } else {
                var jdx = idx;
                while (input[jdx] != ' ') : (jdx += 1) {}
                src.right = Vals{ .idn = input[idx..jdx] };
                idx = jdx;
            }
            idx += 1;
        }

        idx += 3;
        var wire: []const u8 = undefined;
        var jdx = idx;
        while (input[jdx] != '\n') : (jdx += 1) {}
        wire = input[idx..jdx];
        idx = jdx;

        try gates.put(wire, src);
        try gates_copy.put(wire, src);
    }
    try evaluate_wires(&gates, &wires);

    res_1 = wires.get("a") orelse unreachable;
    gates_copy.getPtr("b").?.* = Source{ .op = .PASS, .left = Vals{ .num = res_1 } };
    wires.clearAndFree();

    try evaluate_wires(&gates_copy, &wires);
    res_2 = wires.get("a") orelse unreachable;

    print("part 1: {d}\npart 2: {d}", .{ res_1, res_2 });
}

fn evaluate_wires(pending_wires: *std.StringHashMap(Source), wires: *std.StringHashMap(u16)) !void {
    while (pending_wires.count() != 0) {
        var iter = pending_wires.iterator();
        while (iter.next()) |entry| {
            const value: u16 = switch (entry.value_ptr.op) {
                .PASS => switch (entry.value_ptr.left) {
                    .num => |val| val,
                    .idn => |idn| wires.get(idn) orelse continue,
                    .exp => unreachable,
                },
                .NOT => 0xffff ^ switch (entry.value_ptr.left) {
                    .num => |val| val,
                    .idn => |idn| (wires.get(idn) orelse continue),
                    .exp => unreachable,
                },
                else => blk: {
                    const lval = switch (entry.value_ptr.left) {
                        .num => |val| val,
                        .idn => |idn| wires.get(idn) orelse continue,
                        .exp => unreachable,
                    };
                    const rval = switch (entry.value_ptr.right) {
                        .num => |val| val,
                        .idn => |idn| wires.get(idn) orelse continue,
                        else => 0,
                    };
                    const exp = switch (entry.value_ptr.right) {
                        .exp => |val| val,
                        else => 0,
                    };
                    break :blk switch (entry.value_ptr.op) {
                        .AND => lval & rval,
                        .OR => lval | rval,
                        .RSHIFT => lval >> exp,
                        .LSHIFT => lval << exp,
                        else => unreachable,
                    };
                },
            };
            try wires.put(entry.key_ptr.*, value);
            _ = pending_wires.remove(entry.key_ptr.*);
            break;
        }
    }
}

const Operation = enum {
    PASS,
    AND,
    OR,
    NOT,
    LSHIFT,
    RSHIFT,
};

const Vals = union(enum) {
    num: u16,
    exp: u4,
    idn: []const u8,
};

const Source = struct {
    op: Operation = .PASS,
    left: Vals = .{ .num = 0 },
    right: Vals = .{ .num = 0 },
};
