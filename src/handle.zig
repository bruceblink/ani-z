const std = @import("std");
const httpz = @import("httpz");
const pg = @import("pg");
const root = @import("root.zig");
const App = root.App;


pub const AniInfo = struct {
    id: i64,
    title: []const u8,
    detailUrl: []const u8,
    platform: []const u8,
};

pub fn index(_: *App, _: *httpz.Request, res: *httpz.Response) !void {
    res.body =
    \\<!DOCTYPE html>
    \\ <h1>Hello this ani-z</h1>
    ;
}

pub fn getAniInfo(app: *App, req: *httpz.Request, res: *httpz.Response) !void {
    res.status = 200;
    const ani_id = req.param("id").?;

    var row = try app.db_pool.row("select title, detail_url, platform from ani_info where id = $1", .{ani_id}) orelse {
        res.status = 404;
        res.body = "Not found";
        return;
    };
    defer row.deinit() catch {};

    try res.json(.{
        .id = ani_id,
        .title = row.get([]u8, 0),
        .detailUrl = row.get([]u8, 1),
        .platform = row.get([]u8, 2),
    }, .{});
}

pub fn getAniInfoList(app: *App, req: *httpz.Request, res: *httpz.Response) !void {
    res.status = 200;

    const param = if (try req.json(root.PageParam)) |p| p else root.PageParam{};
    const offset = (param.page - 1) * param.page_size;

    var result = try app.db_pool.query(
        \\SELECT id, title, detail_url, platform, COUNT(*) OVER() AS total_count
        \\FROM ani_info
        \\ORDER BY id
        \\LIMIT $1
        \\OFFSET $2
    , .{ param.page_size, offset });
    defer result.deinit();

    var list = std.ArrayList(AniInfo).init(app.allocator);
    defer list.deinit();

    var total_count: i64 = 0;

    while (try result.next()) |row| {
        try list.append(.{
            .id = row.get(i64, 0),
            .title = row.get([]const u8, 1),
            .detailUrl = row.get([]const u8, 2),
            .platform = row.get([]const u8, 3),
        });
        total_count = row.get(i64, 4);
    }
    const AniPage = root.PageData(AniInfo);
    const page_res = AniPage.init(
        list.items,
        total_count,
        param.page,
        param.page_size,
    );

    try res.json(page_res, .{});
}