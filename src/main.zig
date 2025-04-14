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

const ViewParams = struct {
    x_offset: f32,
    y_offset: f32,
    forced_size: f32,
    custom_size: f32,
    x_rotation: f32, //radian
    y_rotation: f32, //radian
    z_rotation: f32, //radian
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

fn drawMap(mapAllocated: std.ArrayList(std.ArrayList(Vec3)), viewParams: ViewParams) void {
    var ctx: RawContent = undefined;
    var j: usize = 0;
    var i: usize = 0;

    while (true) {
        defer {
            i += 1;
            j = 0;
        }
        while (true) {
            defer j += 1;
            ctx = getRawContent(mapAllocated, i, j);

            if (ctx.right != null) {
                rl.drawLine(@intFromFloat(viewParams.x_offset + ctx.center.?.x * (viewParams.forced_size * viewParams.custom_size)), @intFromFloat(viewParams.y_offset + ctx.center.?.y * (viewParams.forced_size * viewParams.custom_size)), @intFromFloat(viewParams.x_offset + ctx.right.?.x * (viewParams.forced_size * viewParams.custom_size)), @intFromFloat(viewParams.y_offset + ctx.right.?.y * (viewParams.forced_size * viewParams.custom_size)), .white);
            }
            if (ctx.down != null) {
                rl.drawLine(@intFromFloat(viewParams.x_offset + ctx.center.?.x * (viewParams.forced_size * viewParams.custom_size)), @intFromFloat(viewParams.y_offset + ctx.center.?.y * (viewParams.forced_size * viewParams.custom_size)), @intFromFloat(viewParams.x_offset + ctx.down.?.x * (viewParams.forced_size * viewParams.custom_size)), @intFromFloat(viewParams.y_offset + ctx.down.?.y * (viewParams.forced_size * viewParams.custom_size)), .white);
            }

            if (ctx.right == null) break;
        }

        if (ctx.down == null) break;
    }
}

fn rotateMapY(mapClone: std.ArrayList(std.ArrayList(Vec3)), teta: f32) void {
    for (mapClone.items) |row| {
        for (row.items) |*point| {
            const old_x = point.x;
            const old_z = point.z;

            point.x = (old_x * std.math.cos(teta)) + (old_z * std.math.sin(teta));
            point.z = (old_x * -std.math.sin(teta)) + (old_z * std.math.cos(teta));
        }
    }
}

fn rotateMapX(mapClone: std.ArrayList(std.ArrayList(Vec3)), teta: f32) void {
    for (mapClone.items) |row| {
        for (row.items) |*point| {
            const old_y = point.y;
            const old_z = point.z;

            point.y = (old_y * std.math.cos(teta)) + (old_z * -std.math.sin(teta));
            point.z = (old_y * std.math.sin(teta)) + (old_z * std.math.cos(teta));
        }
    }
}

fn rotateMapZ(mapClone: std.ArrayList(std.ArrayList(Vec3)), teta: f32) void {
    for (mapClone.items) |row| {
        for (row.items) |*point| {
            const old_x = point.x;
            const old_y = point.y;

            point.x = (old_x * std.math.cos(teta)) - (old_y * std.math.sin(teta));
            point.y = (old_x * std.math.sin(teta)) + (old_y * std.math.cos(teta));
        }
    }
}

fn projectMap(mapClone: std.ArrayList(std.ArrayList(Vec3))) void {
    for (mapClone.items) |row| {
        for (row.items) |*point| {
            const old_x = point.x;
            const old_y = point.y;
            const old_z = point.z;

            point.x = (std.math.sqrt(3) * 0.5) * (old_x - old_z);
            point.y = (old_x + old_z) * 0.5 + old_y;
        }
    }
}

fn abs(n: f32) f32 {
    if (n < 0)
        return -n;
    return n;
}

fn centerMap(mapClone: std.ArrayList(std.ArrayList(Vec3)), viewParams: *ViewParams) void {
    var right: f32 = 0;
    var left: f32 = 800;
    var up: f32 = 800;
    var down: f32 = 0;

    for (mapClone.items) |row| {
        for (row.items) |point| {
            if (point.x > right) {
                right = point.x;
            } else if (point.x < left) {
                left = point.x;
            }
            if (point.y < up) {
                up = point.y;
            } else if (point.y > down) {
                down = point.y;
            }
        }
    }

    const right_left = right - left;
    const down_up = down - up;

    var largest_diff: f32 = undefined;
    if (right_left > down_up) {
        largest_diff = right_left;
        viewParams.forced_size = 800 / largest_diff;
        viewParams.y_offset = (800 - (down_up * viewParams.forced_size)) * 0.5;
    } else {
        largest_diff = down_up;
        viewParams.forced_size = 800 / largest_diff;
        viewParams.x_offset = (800 - (right_left * viewParams.forced_size)) * 0.5;
        viewParams.y_offset = -up * viewParams.forced_size;
    }
    std.debug.print(
        \\
        \\
        \\
        \\
        \\
        \\
        \\
        \\
        \\
        \\
        \\
        \\
        \\
        \\
        \\
        \\Map Bounds:
        \\  Left   : {d:.2}
        \\  Right  : {d:.2}
        \\  Up     : {d:.2}
        \\  Down   : {d:.2}
        \\  Width  : {d:.2}
        \\  Height : {d:.2}
        \\  Up_Down: {d:.2}
        \\  Right_l: {d:.2}
        \\
        \\View Params:
        \\  Forced Size : {d:.2}
        \\  X Offset    : {d:.2}
        \\  Y Offset    : {d:.2}
        \\
    , .{ left, right, up, down, right_left, down_up, down_up, right_left, viewParams.forced_size, viewParams.x_offset, viewParams.y_offset });
}

fn captureKey(viewParams: *ViewParams) void {
    const StaticKey = struct {
        var value: rl.KeyboardKey = rl.KeyboardKey.null;
    };

    const keyPressed = rl.getKeyPressed();

    if (keyPressed != rl.KeyboardKey.null) {
        StaticKey.value = keyPressed;
    }

    if (StaticKey.value != rl.KeyboardKey.null and rl.isKeyReleased(StaticKey.value)) {
        StaticKey.value = rl.KeyboardKey.null;
    }

    const rad_2 = 0.0349066;

    switch (StaticKey.value) {
        rl.KeyboardKey.w => viewParams.y_offset -= 10,
        rl.KeyboardKey.s => viewParams.y_offset += 10,
        rl.KeyboardKey.a => viewParams.x_offset -= 10,
        rl.KeyboardKey.d => viewParams.x_offset += 10,
        rl.KeyboardKey.left_bracket => viewParams.custom_size -= 0.2,
        rl.KeyboardKey.right_bracket => viewParams.custom_size += 0.2,
        rl.KeyboardKey.up => viewParams.x_rotation += rad_2,
        rl.KeyboardKey.down => viewParams.x_rotation -= rad_2,
        rl.KeyboardKey.left => viewParams.y_rotation -= rad_2,
        rl.KeyboardKey.right => viewParams.y_rotation += rad_2,
        rl.KeyboardKey.page_up => viewParams.z_rotation += rad_2,
        rl.KeyboardKey.page_down => viewParams.z_rotation -= rad_2,
        rl.KeyboardKey.r => {
            viewParams.z_rotation = 0;
            viewParams.x_rotation = 0;
            viewParams.y_rotation = 0;
        },
        else => return,
    }
}

fn run(mapAllocated: std.ArrayList(std.ArrayList(Vec3))) !void {
    const screenWidth = 800;
    const screenHeight = 800;

    var viewParams: ViewParams = .{
        .x_offset = 0,
        .y_offset = 0,
        .custom_size = 1,
        .forced_size = 1,
        .x_rotation = 5,
        .y_rotation = 2,
        .z_rotation = 3.1,
    };

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

        captureKey(&viewParams);

        rl.beginDrawing();
        rl.setTargetFPS(60);
        defer {
            rl.endDrawing();
            rl.clearBackground(.black);
        }

        // const mousePos = rl.getMousePosition();
        // const x: i32 = @intFromFloat(mousePos.x);
        // const y: i32 = @intFromFloat(mousePos.y);

        rotateMapX(mapClone, viewParams.x_rotation);
        rotateMapY(mapClone, viewParams.y_rotation);
        rotateMapZ(mapClone, viewParams.z_rotation);

        projectMap(mapClone);

        centerMap(mapClone, &viewParams);

        // std.debug.print("{any}\n", .{viewParams});

        // rotateMapX(mapClone, 10);
        drawMap(mapClone, viewParams);

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
