// Hardware text mode color constants
pub const VgaColor = u8;
pub const VGA_COLOR_BLACK = 0;
pub const VGA_COLOR_BLUE = 1;
pub const VGA_COLOR_GREEN = 2;
pub const VGA_COLOR_CYAN = 3;
pub const VGA_COLOR_RED = 4;
pub const VGA_COLOR_MAGENTA = 5;
pub const VGA_COLOR_BROWN = 6;
pub const VGA_COLOR_LIGHT_GREY = 7;
pub const VGA_COLOR_DARK_GREY = 8;
pub const VGA_COLOR_LIGHT_BLUE = 9;
pub const VGA_COLOR_LIGHT_GREEN = 10;
pub const VGA_COLOR_LIGHT_CYAN = 11;
pub const VGA_COLOR_LIGHT_RED = 12;
pub const VGA_COLOR_LIGHT_MAGENTA = 13;
pub const VGA_COLOR_LIGHT_BROWN = 14;
pub const VGA_COLOR_WHITE = 15;

fn vga_entry_color(fg: VgaColor, bg: VgaColor) u8 {
    return fg | (bg << 4);
}

fn vga_entry(uc: u8, color: u8) u16 {
    return @as(u16, uc) | (@as(u16, color) << 8);
}

const VGA_WIDTH = 80;
const VGA_HEIGHT = 25;

pub const terminal = struct {
    var row = @as(usize, 0);
    var column = @as(usize, 0);
    var color = vga_entry_color(VGA_COLOR_LIGHT_GREY, VGA_COLOR_BLACK);

    const buffer = @intToPtr([*]volatile u16, 0xB8000);

    pub fn initialize() void {
        var y = @as(usize, 0);
        while (y < VGA_HEIGHT) : (y += 1) {
            var x = @as(usize, 0);
            while (x < VGA_WIDTH) : (x += 1) {
                putCharAt(' ', color, x, y);
            }
        }
    }

    pub fn setColor(new_color: u8) void {
        color = new_color;
    }

    fn putCharAt(c: u8, new_color: u8, x: usize, y: usize) void {
        const index = y * VGA_WIDTH + x;
        buffer[index] = vga_entry(c, new_color);
    }

    fn putChar(c: u8) void {
        switch (c) {
            // check for special chars

            // newline
            '\n' => {
                row += 1;
                column = @as(usize, 0);
                return;
            },

            // tab
            '\t' => {
                column += 5;
                return;
            },

            else => {
                putCharAt(c, color, column, row);
                column += 1;
           },
        }
        
        if (column == VGA_WIDTH) {
            column = 0;
            row += 1;
            if (row == VGA_HEIGHT)
                row = 0;
        }
    }

    pub fn write(data: []const u8) void {
        for (data) |c|
            putChar(c);
    }

    // print with color escapes
    // automatically calls setColor()
    pub fn writef(comptime data: []const u8) void {
        var skip: i32 = 0;
        for (data) |c, i| {
            // check if you need to skip
            if (skip > 0) {
                skip = skip - 1;
                continue;
            }

            // color escapes
            if (c == '%' and data[i + 1] == '[' and data.len > i + 2) {
                const num = data[i + 2];
                const col = num - '0'; // convert color to a number rather than a char
                
                setColor(col);
                // skip twice after this
                skip = 2;
                continue;
            }

            putChar(c);
        }
    }
};
