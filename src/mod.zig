pub const structures = struct {
    pub const Stack = @import("structures/stack.zig").Stack;
    pub const Queue = @import("structures/queue.zig").Queue;
    pub const Set = @import("structures/set.zig").Set;
};

pub const cmp = struct {
    pub const CmpResult = @import("cmp.zig").CmpResult;
    pub const CmpErr = @import("cmp.zig").CmpErr;
};
