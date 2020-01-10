const builtin = @import("builtin");
const vga = @import("lib/vga.zig");
const util = @import("lib/util.zig");

const write = vga.terminal.write;
const writef = vga.terminal.writef;

const MultiBoot = packed struct {
    magic: i32,
    flags: i32,
    checksum: i32,
};

const ALIGN = 1 << 0;
const MEMINFO = 1 << 1;
const MAGIC = 0x1BADB002;
const FLAGS = ALIGN | MEMINFO;

// multiboot header
export var multiboot align(4) linksection(".multiboot") = MultiBoot{
    .magic = MAGIC,
    .flags = FLAGS,
    .checksum = -(MAGIC + FLAGS),
};

export var stack_bytes: [16 * 1024]u8 align(16) linksection(".bss") = undefined;
const stack_bytes_slice = stack_bytes[0..];

// actual asm start section
// call kmain and halt
export nakedcc fn _start() void {
    @newStackCall(stack_bytes_slice, kmain);
    util.halt();
}

fn panic(msg: []const u8, error_return_trace: ?*builtin.StackTrace) void {
    @setCold(true);
    vga.terminal.write("KERNEL PANIC: ");
    vga.terminal.write(msg);
    util.halt();
}

// Whale ascii
const ASCII = 
\\     .-
\\'--./ /     _.---.
\\'-,  (__..--       \
\\   \          .     |
\\    \,.__.   ,__.--/
\\     '._/_.'_____/
;

//
// MAIN
//
fn kmain() void {
    // Welcome with some fancy colors
    vga.terminal.initialize();

    write("Booted FinfetchOS 1.0\n");
    vga.terminal.setColor(1);
    write(ASCII);
    vga.terminal.setColor(7);

    // wait but don't halt
    while (true) {}
    write("While loop broken\n");
}
