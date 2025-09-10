const std = @import("std");
const pg = @import("pg");

pub const App = struct {
    allocator: std.mem.Allocator,
    db_pool: *pg.Pool, // 数据库连接池作为字段

    const Self = @This();

    /// 初始化 App，同时初始化数据库连接池
    pub fn init(allocator: std.mem.Allocator) !Self {
        const pool = try pg.Pool.init(allocator, .{
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

        return Self{
            .allocator = allocator,
            .db_pool = pool,
        };
    }

    /// 清理 App（关闭数据库连接池等资源）
    pub fn deinit(self: *Self) void {
        self.db_pool.deinit();
    }

    /// 获取数据库连接池
    pub fn get_db_pool(self: *Self) *pg.Pool {
        return self.db_pool;
    }
};

test "test get env var" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();


    const stdout = std.io.getStdOut().writer();

    // 如果存在，返回环境变量字符串；如果不存在，返回 error
    const value = std.process.getEnvVarOwned(allocator, "DATABASE_URL") catch |err| switch (err) {
        error.EnvironmentVariableNotFound => {
            try stdout.print("DATABASE_URL 未设置，使用默认值\n", .{});
            return;
        },
        else => return err,
    };
    defer allocator.free(value);

    try std.testing.expectEqualStrings("postgresql://postgres:password@localhost:5432/newsletter", value);
}

pub const PageParam = struct {
    page: i64 = 1,          // 当前页码（1开始）
    page_size: i64 = 10,    // 每页数量
};

pub fn PageData(comptime T: type) type {
    return struct {
        items: []T,
        total_count: usize,
        page: usize,
        page_size: usize,
        total_pages: usize,

        const Self = @This();

        pub fn init(items: []T, total_count: usize, page: usize, page_size: usize) Self {
            return Self{
                .items = items,
                .total_count = total_count,
                .page = page,
                .page_size = page_size,
                .total_pages = (total_count + page_size - 1) / page_size,  // 向上取整
            };
        }
    };
}