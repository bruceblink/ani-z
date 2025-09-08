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

pub const PageParam = struct {
    page: i64 = 1,          // 当前页码（1开始）
    page_size: i64 = 10,    // 每页数量
};

pub fn PageData(comptime T: type) type {
    return struct {
        items: []T,
        total: i64,
        page: i64,
        page_size: i64,

        const Self = @This();

        pub fn init(items: []T, total: i64, page: i64, page_size: i64) Self {
            return Self{
                .items = items,
                .total = total,
                .page = page,
                .page_size = page_size,
            };
        }
    };
}