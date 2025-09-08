const std = @import("std");
const httpz = @import("httpz");
const pg = @import("pg");
const root = @import("root.zig");
const App = root.App;
const handle = @import("handle.zig");


pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    // 初始化App应用上下文
    var app = try App.init(allocator);
    defer app.deinit();

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
    router.get("/", handle.index, .{});
    router.get("/api/anis/:id", handle.getAniInfo, .{});
    router.post("/api/anis", handle.getAniInfoList, .{});


    std.debug.print("server listening: http://localhost:{?}\n", .{ server.config.port });
    // blocks
    try server.listen();
}