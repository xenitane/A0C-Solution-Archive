const std = @import("std");

const print = std.debug.print;

const TIME_LIMIT = 2503;

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
    return buffer[0..file_size];
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

    var idx: usize = 0;
    var dists = [_]u64{0} ** TIME_LIMIT;
    const leaders = try ac.alloc(std.ArrayList(u8), TIME_LIMIT);
    defer ac.free(leaders);
    for (leaders) |*leader| leader.* = std.ArrayList(u8).init(ac);
    defer for (leaders) |*leader| leader.deinit();

    var rdr: u8 = 0;
    while (idx < input.len) {
        var speed: u64 = 0;
        var flight_duration: u64 = 0;
        var resting_period: u64 = 0;
        while (!std.ascii.isDigit(input[idx])) : (idx += 1) {}
        while (std.ascii.isDigit(input[idx])) : (idx += 1) speed = speed * 10 + input[idx] - 48;
        while (!std.ascii.isDigit(input[idx])) : (idx += 1) {}
        while (std.ascii.isDigit(input[idx])) : (idx += 1) flight_duration = flight_duration * 10 + input[idx] - 48;
        while (!std.ascii.isDigit(input[idx])) : (idx += 1) {}
        while (std.ascii.isDigit(input[idx])) : (idx += 1) resting_period = resting_period * 10 + input[idx] - 48;
        while (input[idx] != '\n') : (idx += 1) {}
        idx += 1;

        res_1 = @max(res_1, get_distance(speed, flight_duration, resting_period, TIME_LIMIT));
        for (0..TIME_LIMIT) |i| {
            const dist = get_distance(speed, flight_duration, resting_period, i + 1);
            if (dist > dists[i]) {
                dists[i] = dist;
                leaders[i].clearAndFree();
            }
            if (dists[i] == dist) try leaders[i].append(rdr);
        }
        rdr += 1;
    }
    const points = try ac.alloc(u64, rdr);
    defer ac.free(points);
    for (points) |*p| p.* = 0;
    for (0..TIME_LIMIT) |i| {
        for (leaders[i].items) |l| points[l] += 1;
    }
    res_2 = 0;
    for (points) |p| res_2 = @max(res_2, p);

    print("part 1: {d}\npart 2: {d}", .{ res_1, res_2 });
}

fn get_distance(speed: u64, flight_duration: u64, resting_period: u64, time_span: u64) u64 {
    return speed * (flight_duration * (time_span / (flight_duration + resting_period)) + @min(flight_duration, time_span % (flight_duration + resting_period)));
}
