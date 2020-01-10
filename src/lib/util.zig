// OS utilities

// hang the system
pub fn halt() void {
    asm volatile (
         \\hlt
    );
}
