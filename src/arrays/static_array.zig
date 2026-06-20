const std = @import("std");
const Allocator = std.mem.Allocator;
const testing = std.testing;
const DEFAULT_ARRAY_CAPACITY = 256;

const StaticArrayError = error{ ArrayFull, OutOfBound };

fn StaticArray(comptime T: type) type {
    return struct {
        allocator: Allocator,
        items: []T,
        length: u32,

        const Self = @This();

        /// initialisation
        fn init(_allocator: Allocator) !Self {
            return Self{
                .allocator = _allocator,
                .length = 0,
                .items = try _allocator.alloc(T, DEFAULT_ARRAY_CAPACITY),
            };
        }

        fn push_back(self: *Self, value: T) !void {
            if (self.length >= self.items.len) {
                return StaticArrayError.ArrayFull;
            }

            self.items[self.length] = value;
            self.length += 1;
        }

        fn pop_back(self: *Self) ?T {
            if (self.length == 0) return null;
            self.length -= 1;
            return self.items[self.length];
        }

        fn insert_at(self: *Self, index: usize, value: T) !void {
            if (index >= self.length) {
                return StaticArrayError.OutOfBound;
            }

            self.items[index] = value;
        }

        /// free array memory
        fn deinit(self: Self) void {
            self.allocator.free(self.items);
        }
    };
}

test "StaticArray: init" {
    const arr = try StaticArray(i32).init(testing.allocator);
    defer arr.deinit();
}

test "StaticArray: push_back" {
    var arr = try StaticArray(i32).init(testing.allocator);
    defer arr.deinit();

    for (0..5) |i| {
        try arr.push_back(@intCast(i + 10));
    }
    try testing.expectEqual(10, arr.items[0]);
    try testing.expectEqual(11, arr.items[1]);
    try testing.expectEqual(12, arr.items[2]);
    try testing.expectEqual(13, arr.items[3]);
    try testing.expectEqual(14, arr.items[4]);
}

test "StaticArray: pop_back" {
    var arr = try StaticArray(i32).init(testing.allocator);
    defer arr.deinit();

    for (0..5) |i| {
        try arr.push_back(@intCast(i + 10));
    }
    try testing.expectEqual(14, arr.pop_back().?);
    try testing.expectEqual(13, arr.pop_back().?);
    try testing.expectEqual(12, arr.pop_back().?);
    try testing.expectEqual(11, arr.pop_back().?);
    try testing.expectEqual(10, arr.pop_back().?);
    try testing.expectEqual(null, arr.pop_back());
}

test "StaticArray: insert_at" {
    var arr = try StaticArray(i32).init(testing.allocator);
    defer arr.deinit();

    for (0..5) |i| {
        try arr.push_back(@intCast(i + 10));
    }

    try arr.insert_at(2, 67);
    try testing.expectEqual(67, arr.items[2]);

    try testing.expectError(
        StaticArrayError.OutOfBound,
        arr.insert_at(5, 67),
    );
}
