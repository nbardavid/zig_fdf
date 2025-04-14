const std = @import("std");
const expect = std.testing.expect;

pub fn main() void {
    var args = std.process.args();
    var i: usize = 0;
    while (args.next()) |arg| {
        i += 1;
        std.debug.print("arg {d}:{s}\n", .{ i, arg });
    }
}

test "test" {
    try expect(true);
}
