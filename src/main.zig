// const prev_items = mapAllocated.items[0.. mapAllocated.items.len -| 1];
// const curr_items = mapAllocated.items[1..];
// for (prev_items, curr_items) | prev, curr | {
//
// }

// const item_iter = std.mem.window(Vec3, lineArray.items, 2, 1);
//
// while (item_iter.next()) |window| {
//    const  prev, curr = .{window[0], window[1]};
// }

// pub const MyMap = struct {
//     my_points : []Point,
//
//     pub fn at(self : *MyMap, y : usize, x : usize) Point {
//         return self.my_points[y * width, + x];
//     }
// }
//
// const map : ArrayList([]Point);

const std = @import("std");
const rl = @import("raylib");

const expect = std.testing.expect;
const Vec3 = struct { x: f32, y: f32, z: f32 };

fn mapToArrayAlloc(alloc: std.mem.Allocator, mapPath: []u8) !std.ArrayList(std.ArrayList(Vec3)) {
    const file = try std.fs.cwd().openFile(mapPath, .{});
    defer file.close();

    const content: []u8 = file.readToEndAlloc(alloc, 1e6) catch |e| {
        std.log.debug("Canno't read file: {s}: cause: {!}", .{ mapPath, e });
        return error.FileTooBig;
    };
    defer alloc.free(content);

    var splittedMap = std.mem.tokenizeScalar(u8, content, '\n');
    var mapArray = std.ArrayList(std.ArrayList(Vec3)).init(alloc);

    var x: f32 = 0;
    var y: f32 = 0;

    while (splittedMap.next()) |line| {
        defer {
            y += 1;
            x = 0;
        }

        var lineArray = std.ArrayList(Vec3).init(alloc);
        var items = std.mem.tokenizeScalar(u8, line, ' ');

        while (items.next()) |item| {
            defer x += 1;

            try lineArray.append(.{
                .x = x,
                .y = y,
                .z = try std.fmt.parseFloat(f32, item),
            });
        }
        try mapArray.append(lineArray);
    }
    return mapArray;
}

const RawContent = struct {
    left: ?Vec3,
    right: ?Vec3,
    center: ?Vec3,
    up: ?Vec3,
    down: ?Vec3,
};

fn getRawContent(grid: std.ArrayList(std.ArrayList(Vec3)), i: usize, j: usize) RawContent {
    return .{
        .left = if (j > 0) grid.items[i].items[j - 1] else null,
        .right = if (j + 1 < grid.items[i].items.len) grid.items[i].items[j + 1] else null,
        .center = grid.items[i].items[j],
        .up = if (i > 0 and (j < grid.items[i - 1].items.len)) grid.items[i - 1].items[j] else null,
        .down = if (i + 1 < grid.items.len and (j < grid.items[i + 1].items.len)) grid.items[i + 1].items[j] else null,
    };
}

fn drawMap(mapAllocated: std.ArrayList(std.ArrayList(Vec3))) void {
    var ctx: RawContent = undefined;
    var j: usize = 0;
    var i: usize = 0;
    const size: f32 = 20;
    const offset: f32 = 100;

    while (true) {
        defer {
            i += 1;
            j = 0;
        }
        while (true) {
            defer j += 1;
            ctx = getRawContent(mapAllocated, i, j);

            if (ctx.right != null) {
                rl.drawLine(@intFromFloat(offset + ctx.center.?.x * size), @intFromFloat(offset + ctx.center.?.y * size), @intFromFloat(offset + ctx.right.?.x * size), @intFromFloat(offset + ctx.right.?.y * size), .white);
            }
            if (ctx.down != null) {
                rl.drawLine(@intFromFloat(offset + ctx.center.?.x * size), @intFromFloat(offset + ctx.center.?.y * size), @intFromFloat(offset + ctx.down.?.x * size), @intFromFloat(offset + ctx.down.?.y * size), .white);
            }

            if (ctx.right == null) break;
        }

        if (ctx.down == null) break;
    }
}

fn rotateMapX(mapClone: std.ArrayList(std.ArrayList(Vec3)), teta: f32) void {
    for (mapClone.items) |row| {
        for (row.items) |*point| {
            point.y = (point.y * std.math.cos(teta)) + (point.z * -std.math.sin(teta));
            point.z = (point.y * std.math.sin(teta)) + (point.z * std.math.cos(teta));
        }
    }
}

fn run(mapAllocated: std.ArrayList(std.ArrayList(Vec3))) !void {
    const screenWidth = 800;
    const screenHeight = 800;

    rl.initWindow(screenWidth, screenHeight, "test");
    defer rl.closeWindow();

    while (!rl.windowShouldClose()) {
        var mapClone = blk: {
            var clone = try mapAllocated.clone();
            for (mapAllocated.items, 0..) |row, i| {
                clone.items[i] = try row.clone();
            }
            break :blk clone;
        };

        defer {
            for (mapClone.items) |r| r.deinit();
            mapClone.deinit();
        }

        rl.beginDrawing();
        rl.setTargetFPS(240);
        defer {
            rl.endDrawing();
            rl.clearBackground(.black);
        }

        // const mousePos = rl.getMousePosition();
        // const x: i32 = @intFromFloat(mousePos.x);
        // const y: i32 = @intFromFloat(mousePos.y);

        rotateMapX(mapClone, 0.174533);
        drawMap(mapClone);

        // rl.drawPixel(x, y, .white);
        rl.drawFPS(600, 600);
    }
}

pub fn main() !void {
    var debugAlloc: std.heap.DebugAllocator(.{}) = .init;
    defer _ = debugAlloc.deinit();
    const allocator = debugAlloc.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len > 1) {
        const mapAllocated = try mapToArrayAlloc(allocator, args[1]);
        defer {
            for (mapAllocated.items) |item| item.deinit();
            mapAllocated.deinit();
        }
        try run(mapAllocated);
    }

    // const screenWidth = 800;
    // const screenHeight = 800;
    //
    // rl.initWindow(screenWidth, screenHeight, "test");
    // defer rl.closeWindow();
    //
    // while (!rl.windowShouldClose()) {
    //     rl.beginDrawing();
    //
    //     rl.setTargetFPS(240);
    //
    //     defer {
    //         rl.endDrawing();
    //         rl.clearBackground(.black);
    //     }
    //
    //     const mousePos = rl.getMousePosition();
    //     const x: i32 = @intFromFloat(mousePos.x);
    //     const y: i32 = @intFromFloat(mousePos.y);
    //
    //     rl.drawPixel(x, y, .white);
    //
    //     rl.drawText("Salut", 200, 200, 20, .light_gray);
    //     rl.drawFPS(600, 600);
    // }
}
