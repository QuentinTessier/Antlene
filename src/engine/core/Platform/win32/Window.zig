const std = @import("std");
const win32 = struct {
    usingnamespace @import("std").os.windows;
    usingnamespace @import("win32_extended.zig");
};

const WindowExtent = @import("../Window.zig").WindowExtent;
const KeyCode = @import("../Window.zig").KeyCode;
const WindowEvent = @import("../Window.zig").WindowEvent;
const EventBus = @import("../../GlobalEventBus.zig");

const WIN32_TO_HID: [256]u8 = [256]u8{
    0, 0, 0, 0, 0, 0, 0, 0, 42, 43, 0, 0, 0, 40, 0, 0, // 16
    225, 224, 226, 72, 57, 0, 0, 0, 0, 0, 0, 41, 0, 0, 0, 0, // 32
    44, 75, 78, 77, 74, 80, 82, 79, 81, 0, 0, 0, 70, 73, 76, 0, // 48
    39, 30, 31, 32, 33, 34, 35, 36, 37, 38, 0, 0, 0, 0, 0, 0, // 64
    0, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, // 80
    19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 0, 0, 0, 0, 0, // 96
    98, 89, 90, 91, 92, 93, 94, 95, 96, 97, 85, 87, 0, 86, 99, 84, //112
    58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 104, 105, 106, 107, //128
    108, 109, 110, 111, 112, 113, 114, 115, 0, 0, 0, 0, 0, 0, 0, 0, //144
    83, 71, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, //160
    225, 229, 224, 228, 226, 230, 0, 0, 0, 0, 0, 0, 0, 127, 128, 129, //176    L/R shift/ctrl/alt  mute/vol+/vol-
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 51, 46, 54, 45, 55, 56, //192
    53, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, //208
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 47, 49, 48, 52, 0, //224
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, //240
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, //256
};

fn wndProc(hwnd: win32.HWND, msg: win32.UINT, wParam: win32.WPARAM, lParam: win32.LPARAM) callconv(win32.WINAPI) win32.LRESULT {
    switch (msg) {
        win32.WM_CLOSE => {
            _ = win32.destroyWindow(hwnd);
            return 0;
        },
        win32.WM_DESTROY => {
            win32.postQuitMessage(0);
            return 0;
        },
        win32.WM_PAINT => {
            _ = win32.validateRect(hwnd, null);
            return 0;
        },
        win32.WM_EXITSIZEMOVE => {
            _ = win32.postMessageA(hwnd, win32.WM_RESHAPE, 0, 0);
            return 0;
        },
        else => return win32.DefWindowProcA(hwnd, msg, wParam, lParam),
    }
}

pub const Win32Window = struct {
    const Self = @This();

    hInstance: win32.HINSTANCE = undefined,
    hwnd: win32.HWND = undefined,
    dc: win32.HDC = undefined,
    hasFocus: bool = false,
    width: i32,
    height: i32,
    x: i32 = 0,
    y: i32 = 0,
    name: [*:0]const u8,

    pub fn init(name: [*:0]const u8, width: i32, height: i32) Self {
        return Self{
            .name = name,
            .width = width,
            .height = height,
        };
    }

    pub fn create(self: *Self) !bool {
        self.hInstance = win32.getModuleHandle(null);

        var bBrush = win32.getStockObject(win32.BLACK_BRUSH);
        const wcex = win32.WNDCLASSEXA{
            .cbSize = @sizeOf(win32.WNDCLASSEXA),
            .style = win32.CS_HREDRAW | win32.CS_VREDRAW,
            .lpfnWndProc = wndProc,
            .cbClsExtra = 0,
            .cbWndExtra = 0,
            .hInstance = self.hInstance,
            .hIcon = null,
            .hCursor = null,
            .hbrBackground = @ptrCast(bBrush),
            .lpszMenuName = null,
            .lpszClassName = self.name,
            .hIconSm = null,
        };

        _ = win32.registerClassExA(&wcex);
        self.hwnd = win32.createWindowExA(
            0,
            self.name,
            self.name,
            win32.WS_OVERLAPPEDWINDOW | win32.WS_CLIPCHILDREN | win32.WS_CLIPSIBLINGS | win32.WS_SYSMENU | win32.WS_VISIBLE,
            self.x,
            self.y,
            self.width,
            self.height,
            null,
            null,
            self.hInstance,
            null,
        );
        _ = win32.showWindow(self.hwnd, win32.SW_SHOW);
        self.dc = win32.GetDC(self.hwnd) orelse unreachable;
        return true;
    }

    fn convertMessage(self: *Self, msg: win32.MSG) !void {
        const mX: i16 = win32.loWord(msg.lParam);
        const mY: i16 = win32.hiWord(msg.lParam);

        switch (msg.message) {
            win32.WM_QUIT => {
                const e = WindowEvent{ .close = void{} };
                EventBus.broadcast(WindowEvent, self, e);
                return;
            },
            win32.WM_MOUSEMOVE => {
                const e = WindowEvent{ .mouseMove = .{
                    .x = @intCast(mX),
                    .y = @intCast(mY),
                } };
                EventBus.broadcast(WindowEvent, self, e);
                return;
            },
            win32.WM_LBUTTONDOWN => {
                const e = WindowEvent{ .mouseDown = .Left };
                EventBus.broadcast(WindowEvent, self, e);
                return;
            },
            win32.WM_MBUTTONDOWN => {
                const e = WindowEvent{ .mouseDown = .Middle };
                EventBus.broadcast(WindowEvent, self, e);
                return;
            },
            win32.WM_RBUTTONDOWN => {
                const e = WindowEvent{ .mouseDown = .Right };
                EventBus.broadcast(WindowEvent, self, e);
                return;
            },
            win32.WM_LBUTTONUP => {
                const e = WindowEvent{ .mouseUp = .Left };
                EventBus.broadcast(WindowEvent, self, e);
                return;
            },
            win32.WM_MBUTTONUP => {
                const e = WindowEvent{ .mouseUp = .Middle };
                EventBus.broadcast(WindowEvent, self, e);
                return;
            },
            win32.WM_RBUTTONUP => {
                const e = WindowEvent{ .mouseUp = .Right };
                EventBus.broadcast(WindowEvent, self, e);
                return;
            },
            win32.WM_MOUSEWHEEL => {
                const value = win32.hiWord(@intCast(msg.wParam));
                const e = WindowEvent{ .mouseScroll = @floatFromInt(value) };
                EventBus.broadcast(WindowEvent, self, e);
                return;
            },
            win32.WM_KEYDOWN => {
                const e = WindowEvent{
                    .keyDown = @enumFromInt(WIN32_TO_HID[@as(usize, msg.wParam)]),
                };
                EventBus.broadcast(WindowEvent, self, e);
                return;
            },
            win32.WM_KEYUP => {
                const e = WindowEvent{
                    .keyUp = @enumFromInt(WIN32_TO_HID[@as(usize, msg.wParam)]),
                };
                EventBus.broadcast(WindowEvent, self, e);
                return;
            },
            win32.WM_ACTIVE => {
                self.hasFocus = msg.wParam != 0x0006;
                const e = WindowEvent{ .focus = self.hasFocus };
                EventBus.broadcast(WindowEvent, self, e);
                return;
            },
            win32.WM_RESHAPE => {
                const old = self.getWindowExtent();
                if (!self.hasFocus) {
                    _ = win32.postMessageA(self.hwnd, win32.WM_RESHAPE, msg.wParam, msg.lParam);
                    self.hasFocus = true;
                }

                var rect: win32.RECT = win32.RECT{ .left = 0, .right = 0, .top = 0, .bottom = 0 };
                {
                    _ = win32.getClientRect(self.hwnd, &rect);
                    const w = rect.right - rect.left;
                    const h = rect.bottom - rect.top;
                    const e = WindowEvent{
                        .resize = .{
                            .old = old,
                            .new = WindowExtent{ .width = @intCast(w), .height = @intCast(h) },
                        },
                    };
                    EventBus.broadcast(WindowEvent, self, e);
                }

                {
                    _ = win32.getWindowRect(self.hwnd, &rect);
                    const x = rect.left;
                    const y = rect.top;
                    const e = WindowEvent{
                        .moved = .{
                            .old = .{ .x = self.x, .y = self.y },
                            .new = .{ .x = x, .y = y },
                        },
                    };
                    EventBus.broadcast(WindowEvent, self, e);
                }
            },
            else => {
                return;
            },
        }
    }

    pub fn pollEvents(self: *Self) !void {
        var msg: win32.MSG = undefined;
        while (win32.peekMessageA(&msg, null, 0, 0, win32.PM_REMOVE)) {
            _ = win32.translateMessage(&msg);

            try self.convertMessage(msg);

            _ = win32.dispatchMessageA(&msg);
        }
    }

    pub fn queryWindowExtent(self: *Self) void {
        var rect: win32.RECT = undefined;
        if (win32.getWindowRect(self.hwnd, &rect)) {
            if (self.width != rect.right - rect.left or self.height != rect.bottom - rect.top) {
                EventBus.broadcast(WindowEvent, self, WindowEvent{
                    .resize = .{
                        .old = .{ .width = @intCast(self.width), .height = @intCast(self.height) },
                        .new = .{ .width = @intCast(rect.right - rect.left), .height = @intCast(rect.bottom - rect.top) },
                    },
                });
            }
            self.width = rect.right - rect.left;
            self.height = rect.bottom - rect.top;
        }
    }

    pub fn getWindowExtent(self: *Self) WindowExtent {
        return WindowExtent{ .width = @intCast(self.width), .height = @intCast(self.height) };
    }

    pub fn getDC(self: *const Self) win32.HDC {
        return self.dc;
    }

    pub fn swapBuffers(self: *Self) void {
        _ = win32.SwapBuffers(self.dc);
    }

    pub fn close(self: *Self) void {
        _ = self;
    }
};
