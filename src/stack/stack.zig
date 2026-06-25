const std = @import("std");
const Allocator = std.mem.Allocator;
const testing = std.testing;

const MAX_STACK_CAPACITY = 256;

const StackError = error{Overflow};

fn Stack(comptime T: type) type {
    return struct {
        allocator: Allocator,
        items: []T,
        pos: u32,

        const Self = @This();

        fn init(_allocator: Allocator) !Self {
            return Self{
                .allocator = _allocator,
                .pos = 0,
                .items = try _allocator.alloc(T, MAX_STACK_CAPACITY),
            };
        }

        fn deinit(self: *Self) void {
            self.allocator.free(self.items);
        }

        fn top(self: *Self) ?T {
            const pos = self.pos;
            if (pos == 0) return null;

            return self.items[pos - 1];
        }

        fn push(self: *Self, value: T) !void {
            const pos = self.pos;

            if (pos >= MAX_STACK_CAPACITY) return StackError.Overflow;

            self.items[pos] = value;
            self.pos = pos + 1;
        }

        fn pop(self: *Self) ?T {
            const pos = self.pos;

            if (pos == 0) return null;

            self.pos = pos - 1;
            self.items[pos] = undefined;

            return self.items[self.pos];
        }
    };
}

test "Stack: init" {
    var stack = try Stack(i32).init(testing.allocator);
    defer stack.deinit();
    try testing.expect(stack.pos == 0);
    try testing.expect(stack.top() == null);
}

test "Stack: push" {
    var stack = try Stack(i32).init(testing.allocator);
    defer stack.deinit();

    for (0..5) |i| {
        try stack.push(@intCast(i + 10));
    }

    try testing.expectEqual(5, stack.pos);
    try testing.expectEqual(14, stack.top().?);
}

test "Stack: push -- overflow" {
    var stack = try Stack(i32).init(testing.allocator);
    defer stack.deinit();

    for (0..MAX_STACK_CAPACITY) |i| {
        try stack.push(@intCast(i + 10));
    }

    try testing.expectEqual(MAX_STACK_CAPACITY, stack.pos);
    try testing.expectError(StackError.Overflow, stack.push(4));
}

test "Stack: pop" {
    var stack = try Stack(i32).init(testing.allocator);
    defer stack.deinit();

    for (0..5) |i| {
        try stack.push(@intCast(i + 10));
    }

    try testing.expectEqual(14, stack.pop().?);
    try testing.expectEqual(13, stack.pop().?);
    try testing.expectEqual(12, stack.pop().?);
    try testing.expectEqual(11, stack.pop().?);
    try testing.expectEqual(10, stack.pop().?);
    try testing.expectEqual(null, stack.pop());
}
