const std = @import("std");
const pg = @import("pg");

pub const App = struct {
    db: *pg.Pool,
    allocator: std.mem.Allocator,
};

pub const AniInfo = struct {
    id: i64,
    title: []const u8,
    detailUrl: []const u8,
    platform: []const u8,
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