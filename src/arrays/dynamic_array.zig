const std = @import("std");
const Allocator = std.mem.Allocator;
const testing = std.testing;
const INITIAL_ARRAY_CAPACITY = 10;

const DynamicArrayError = error{OutOfBound};

fn DynamicArray(comptime T: type) type {
    return struct {
        allocator: Allocator,
        items: []T,
        length: u32,
        capacity: u32,

        const Self = @This();

        /// initialisation
        fn init(_allocator: Allocator) !Self {
            return Self{
                .allocator = _allocator,
                .length = 0,
                .items = try _allocator.alloc(T, INITIAL_ARRAY_CAPACITY),
                .capacity = INITIAL_ARRAY_CAPACITY,
            };
        }

        fn push_back(self: *Self, value: T) !void {
            const len = self.items.len;
            const pos = self.length;

            if (pos == len) {
                var larger = try self.allocator.alloc(T, self.capacity * 2);
                @memcpy(larger[0..len], self.items);

                self.allocator.free(self.items);
                self.items = larger;
            }

            self.items[pos] = value;
            self.length = pos + 1;
        }

        /// returns the array element at [index] and returns null when the index is out of bound.
        fn item_at(self: *Self, index: u32) ?T {
            if (index >= self.length) return null;
            return self.items[index];
        }

        /// remove the element at the back of [Self]
        fn pop_back(self: *Self) ?T {
            if (self.length == 0) return null;
            self.length -= 1;
            return self.items[self.length];
        }

        /// free array memory
        fn deinit(self: Self) void {
            self.allocator.free(self.items);
        }
    };
}

test "DynamicArray: init" {
    const arr = try DynamicArray(i32).init(testing.allocator);
    defer arr.deinit();
}

test "DynamicArray: push_back" {
    var arr = try DynamicArray(i32).init(testing.allocator);
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

test "DynamicArray: index_at" {
    var arr = try DynamicArray(i32).init(testing.allocator);
    defer arr.deinit();

    for (0..5) |i| {
        try arr.push_back(@intCast(i + 10));
    }
    try testing.expectEqual(10, arr.item_at(0));
    try testing.expectEqual(11, arr.item_at(1));
    try testing.expectEqual(12, arr.item_at(2));
    try testing.expectEqual(13, arr.item_at(3));
    try testing.expectEqual(14, arr.item_at(4));
}

test "DynamicArray: pop_back" {
    var arr = try DynamicArray(i32).init(testing.allocator);
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
