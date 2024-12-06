const std = @import("std");

const print = std.debug.print;

fn getInput(ac: std.mem.Allocator) ![]const u8 {
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
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const ac = gpa.allocator();
    defer _ = gpa.deinit();
    const input = try getInput(ac);
    defer ac.free(input);
    try solve(input, ac);
}

fn solve(input: []const u8, ac: std.mem.Allocator) !void {
    _ = input;
    _ = ac;
}
