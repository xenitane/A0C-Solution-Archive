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
    idn: []const u8,
};

const Source = struct {
    op: Operation = .PASS,
    left: Vals = .{ .num = 0 },
    right: Vals = .{ .num = 0 },
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa_allocator = gpa.allocator();
    defer _ = gpa.deinit();
    const input = try get_input(gpa_allocator);
    defer gpa_allocator.free(input);

    var res_1: u16 = 0;
    var res_2: u16 = 0;

    var wires = std.StringHashMap(u16).init(gpa_allocator);
    defer wires.deinit();
    var pending_wires = std.StringHashMap(Source).init(gpa_allocator);
    defer pending_wires.deinit();
    var pending_wires_copy = std.StringHashMap(Source).init(gpa_allocator);
    defer pending_wires_copy.deinit();

    const n = input.len;
    var idx: usize = 0;
    while (idx < n) : (idx += 1) {
        var src: Source = .{};
        var op1: ?[]const u8 = null;
        var op2: ?[]const u8 = null;
        var op3: ?[]const u8 = null;
        var wire: []const u8 = undefined;
        var jdx = idx;
        while (input[jdx] != ' ') : (jdx += 1) {}
        op1 = input[idx..jdx];
        idx = jdx + 1;
        if (input[idx] != '-') {
            jdx = idx;
            while (input[jdx] != ' ') : (jdx += 1) {}
            op2 = input[idx..jdx];
            idx = jdx + 1;
        }
        if (input[idx] != '-') {
            jdx = idx;
            while (input[jdx] != ' ') : (jdx += 1) {}
            op3 = input[idx..jdx];
            idx = jdx + 1;
        }
        idx += 3;
        jdx = idx;
        while (input[jdx] != '\n') : (jdx += 1) {}
        wire = input[idx..jdx];
        idx = jdx;

        if (op3) |right_operand| {
            src.right = if (std.ascii.isDigit(right_operand[0])) Vals{ .num = try std.fmt.parseUnsigned(u16, right_operand, 10) } else Vals{ .idn = right_operand };
            src.left = blk: {
                const left_operand = op1 orelse unreachable;
                break :blk if (std.ascii.isDigit(left_operand[0])) Vals{ .num = try std.fmt.parseUnsigned(u16, left_operand, 10) } else Vals{ .idn = left_operand };
            };
            src.op = switch ((op2 orelse unreachable)[0]) {
                'A' => .AND,
                'O' => .OR,
                'L' => .LSHIFT,
                'R' => .RSHIFT,
                else => unreachable,
            };
        } else if (op2) |source| {
            src.op = .NOT;
            src.left = if (std.ascii.isDigit(source[0])) Vals{ .num = try std.fmt.parseUnsigned(u16, source, 10) } else Vals{ .idn = source };
        } else if (op1) |source| {
            src.left = if (std.ascii.isDigit(source[0])) Vals{ .num = try std.fmt.parseUnsigned(u16, source, 10) } else Vals{ .idn = source };
        } else {
            unreachable;
        }
        try pending_wires.put(wire, src);
        try pending_wires_copy.put(wire, src);
    }
    try evaluate_wires(&pending_wires, &wires);

    res_1 = wires.get("a") orelse unreachable;
    pending_wires_copy.getPtr("b").?.* = Source{ .op = .PASS, .left = Vals{ .num = res_1 } };
    wires.clearAndFree();

    try evaluate_wires(&pending_wires_copy, &wires);
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
                },
                .NOT => 0xffff ^ switch (entry.value_ptr.left) {
                    .num => |val| val,
                    .idn => |idn| (wires.get(idn) orelse continue),
                },
                else => blk: {
                    const lval = switch (entry.value_ptr.left) {
                        .num => |val| val,
                        .idn => |idn| wires.get(idn) orelse continue,
                    };
                    const rval = switch (entry.value_ptr.right) {
                        .num => |val| val,
                        .idn => |idn| wires.get(idn) orelse continue,
                    };
                    break :blk switch (entry.value_ptr.op) {
                        .AND => lval & rval,
                        .OR => lval | rval,
                        .RSHIFT => zzz: {
                            const exp: u4 = switch (rval) {
                                1 => 1,
                                2 => 2,
                                3 => 3,
                                5 => 5,
                                15 => 15,
                                else => unreachable,
                            };
                            break :zzz lval >> exp;
                        },
                        .LSHIFT => zzz: {
                            const exp: u4 = switch (rval) {
                                1 => 1,
                                2 => 2,
                                3 => 3,
                                5 => 5,
                                15 => 15,
                                else => unreachable,
                            };
                            break :zzz lval << exp;
                        },
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
