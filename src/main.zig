const std = @import("std");
const httpz = @import("httpz");
const pg = @import("pg");

const App = struct {
    db: *pg.Pool,
    allocator: std.mem.Allocator,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    // 初始化数据库连接池
    var db = try init_db_pool(allocator);
    defer db.deinit();

    var app = App {
        .db = db,
        .allocator = allocator,
    };
    // More advance cases will use a custom "Handler" instead of "void".
    // The last parameter is our handler instance, since we have a "void"
    // handler, we passed a void ({}) value.
    var server = try httpz.Server(*App).init(allocator, .{.port = 5882}, &app);
    defer {
        // clean shutdown, finishes serving any live request
        server.stop();
        server.deinit();
    }

    var router = try server.router(.{});
    router.get("/", index, .{});
    router.get("/api/anis/:id", getAniInfo, .{});
    router.get("/api/anis", getAniInfoList, .{});


    std.debug.print("server listening: http://localhost:{?}\n", .{ server.config.port });
    // blocks
    try server.listen();
}

pub fn init_db_pool(allocator: std.mem.Allocator) !*pg.Pool {
    return try pg.Pool.init(allocator, .{
        .size = 5,
        .connect = .{
            .port = 5432,
            .host = "127.0.0.1",
        },
        .auth = .{
            .username = "postgres",
            .database = "newsletter",
            .password = "password",
            .timeout = 10_000,
        },
    });
}


fn index(_: *App, _: *httpz.Request, res: *httpz.Response) !void {
    res.body =
    \\<!DOCTYPE html>
    \\ <h1>Hello this ani-z</h1>
    ;
}

fn getAniInfo(app: *App, req: *httpz.Request, res: *httpz.Response) !void {
    res.status = 200;
    const ani_id = req.param("id").?;

    var row = try app.db.row("select title, detail_url, platform from ani_info where id = $1", .{ani_id}) orelse {
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

const AniInfo = struct {
    id: i64,
    title: []const u8,
    detailUrl: []const u8,
    platform: []const u8,
};

fn getAniInfoList(app: *App, _: *httpz.Request, res: *httpz.Response) !void {
    res.status = 200;

    var result = try app.db.query(
        "select id, title, detail_url, platform from ani_info limit 10",
        .{},
    );
    defer result.deinit() ;

    // 用 ArrayList 动态收集 AniInfo
    var list = std.ArrayList(AniInfo).init(app.allocator);
    defer list.deinit();

    while (try result.next()) |row| {
        // 这里编译器会 自动推断类型是AniInfo，所以不需要显式定义一个AniInfo struct
        try list.append(.{
            .id = row.get(i64, 0),        // 用 u64 对应 id
            .title = row.get([]u8, 1),
            .detailUrl = row.get([]u8, 2),
            .platform = row.get([]u8, 3),
        });
    }

    // 输出 JSON 数组
    try res.json(list.items, .{});
}