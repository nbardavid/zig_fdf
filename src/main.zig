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

const COS30: f32 = 0.86602540378;
const SIN30: f32 = 0.5;

const Color = struct {
    value: rl.Color,
    r: i32,
    g: i32,
    b: i32,
};

const Vec3 = struct {
    x: f32,
    y: f32,
    z: f32,
    // color: rl.Color,
    color: Color,
};

fn mapToArrayAlloc(alloc: std.mem.Allocator, mapPath: []u8) !std.ArrayList(std.ArrayList(Vec3)) {
    const file = try std.fs.cwd().openFile(mapPath, .{});
    defer file.close();

    const content: []u8 = file.readToEndAlloc(alloc, 1e9) catch |e| {
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

            var parsed_item = std.mem.tokenizeScalar(u8, item, ',');
            var peek_str: []const u8 = "0";
            var color: [8]u8 = .{ '0', 'x', 'F', 'F', 'F', 'F', 'F', 'F' };

            if (parsed_item.next()) |value| peek_str = value;
            if (parsed_item.next()) |value| {
                @memcpy(color[0..], value);
                // std.debug.print("{s}\n\n", .{color});
            }
            // const peek_str = parsed_item.next() orelse return error.MissingZ;
            // const color: ?[]const u8 = parsed_item.next();
            const parsed_color = try std.fmt.parseInt(u32, color[0..], 0);

            try lineArray.append(.{
                .x = x,
                .y = y,
                .z = try std.fmt.parseFloat(f32, peek_str),
                .color = .{
                    .value = rl.Color.fromInt(parsed_color),
                    .r = @as(u8, @intCast((parsed_color >> 16) & 0xFF)),
                    .g = @as(u8, @intCast((parsed_color >> 8) & 0xFF)),
                    .b = @as(u8, @intCast((parsed_color) & 0xFF)),
                },
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
    size: f32,
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

fn getGradientColor(a: Color, b: Color, t: f32) rl.Color {
    return rl.Color{
        .r = @intFromFloat(std.math.lerp(@as(f32, @floatFromInt(a.r)), @as(f32, @floatFromInt(b.r)), t)),
        .g = @intFromFloat(std.math.lerp(@as(f32, @floatFromInt(a.g)), @as(f32, @floatFromInt(b.g)), t)),
        .b = @intFromFloat(std.math.lerp(@as(f32, @floatFromInt(a.b)), @as(f32, @floatFromInt(b.b)), t)),
        .a = 255,
    };
}

fn drawLineGradient(img: *rl.Image, a: Vec3, b: Vec3) !void {
    const dx: f32 = b.x - a.x;
    const dy: f32 = b.y - a.y;
    const gradient: bool = (a.color.value.toInt() != b.color.value.toInt());

    const steps: f32 = @max(@abs(dx), @abs(dy));

    const step_x: f32 = dx / steps;
    const step_y: f32 = dy / steps;

    var x: f32 = a.x;
    var y: f32 = a.y;

    var i: usize = 0;

    //for
    while (i < @as(usize, @intFromFloat(steps))) : (i += 1) {
        const color = if (gradient) getGradientColor(a.color, b.color, @as(f32, @floatFromInt(i)) / steps) else rl.Color{
            .r = @intCast(a.color.r),
            .g = @intCast(a.color.g),
            .b = @intCast(a.color.b),
            .a = 255,
        };

        rl.imageDrawPixel(img, @intFromFloat(x), @intFromFloat(y), color);

        x += step_x;
        y += step_y;
    }
}

fn isPointInScreen(point: Vec3, width: f32, height: f32) bool {
    return (point.x > 0 and point.x < width and point.y > 0 and point.y < height);
}

fn drawMap(img: *rl.Image, mapAllocated: std.ArrayList(std.ArrayList(Vec3))) !void {
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

            if (ctx.right != null and isPointInScreen(ctx.center.?, 800, 800) and isPointInScreen(ctx.right.?, 800, 800)) {
                try drawLineGradient(img, ctx.center.?, ctx.right.?);
            }
            if (ctx.down != null and isPointInScreen(ctx.center.?, 800, 800) and isPointInScreen(ctx.down.?, 800, 800)) {
                try drawLineGradient(img, ctx.center.?, ctx.down.?);
            }

            if (ctx.right == null) break;
        }

        if (ctx.down == null) break;
    }
}

fn rotatePointY(point: *Vec3, teta: f32) void {
    const old_x = point.x;
    const old_z = point.z;

    point.x = (old_x * std.math.cos(teta)) + (old_z * std.math.sin(teta));
    point.z = (old_x * -std.math.sin(teta)) + (old_z * std.math.cos(teta));
}

fn rotatePointZ(point: *Vec3, teta: f32) void {
    const old_x = point.x;
    const old_y = point.y;

    point.x = (old_x * std.math.cos(teta)) - (old_y * std.math.sin(teta));
    point.y = (old_x * std.math.sin(teta)) + (old_y * std.math.cos(teta));
}

fn rotatePointX(point: *Vec3, teta: f32) void {
    const old_y = point.y;
    const old_z = point.z;

    point.y = (old_y * std.math.cos(teta)) + (old_z * -std.math.sin(teta));
    point.z = (old_y * std.math.sin(teta)) + (old_z * std.math.cos(teta));
}

fn projectPoint(point: *Vec3) void {
    const old_x = point.x;
    const old_y = point.y;
    const old_z = point.z;

    point.x = (old_x - old_y) * COS30;
    point.y = (old_x + old_y) * SIN30 - old_z;
}

fn applyViewParams(mapClone: std.ArrayList(std.ArrayList(Vec3)), viewParams: ViewParams) void {
    for (mapClone.items) |row| {
        for (row.items) |*point| {
            point.x = point.x * viewParams.size + viewParams.x_offset;
            point.y = point.y * viewParams.size + viewParams.y_offset;
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
    } else {
        largest_diff = down_up;
    }

    viewParams.forced_size = 800 / largest_diff;
    viewParams.size = viewParams.forced_size * viewParams.custom_size;
    viewParams.x_offset = ((800 - (right_left * viewParams.size)) * 0.5) - (left * viewParams.size);
    viewParams.y_offset = (800 - (down_up * viewParams.size)) * 0.5 - (up * viewParams.size);
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
        rl.KeyboardKey.left_bracket => {
            if (viewParams.custom_size > 0.2)
                viewParams.custom_size -= 0.2;
        },
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

fn computeMap(map: std.ArrayList(std.ArrayList(Vec3)), viewParams: *ViewParams) void {
    for (map.items) |row| {
        for (row.items) |*point| {
            rotatePointX(point, viewParams.x_rotation);
            rotatePointY(point, viewParams.y_rotation);
            rotatePointZ(point, viewParams.z_rotation);
            projectPoint(point);
        }
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
        .size = 1,
        .x_rotation = 5,
        .y_rotation = 2,
        .z_rotation = 3.1,
    };

    rl.initWindow(screenWidth, screenHeight, "fdf");
    var img = rl.genImageColor(800, 800, .black);
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
        rl.setTargetFPS(10000);

        computeMap(mapClone, &viewParams);
        centerMap(mapClone, &viewParams);
        applyViewParams(mapClone, viewParams);

        try drawMap(&img, mapClone);
        const texture = try rl.loadTextureFromImage(img);
        rl.drawTexture(texture, 0, 0, .white);

        defer {
            rl.endDrawing();
            rl.imageClearBackground(&img, .black);
            rl.unloadTexture(texture);
        }
        rl.drawFPS(600, 600);
    }
}

pub fn main() !void {
    var debugAlloc: std.heap.DebugAllocator(.{}) = .init;
    defer _ = debugAlloc.deinit();
    const allocator = debugAlloc.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    rl.setTraceLogLevel(rl.TraceLogLevel.fatal);

    if (args.len > 1) {
        const mapAllocated = try mapToArrayAlloc(allocator, args[1]);
        defer {
            for (mapAllocated.items) |item| item.deinit();
            mapAllocated.deinit();
        }
        try run(mapAllocated);
    }
}
