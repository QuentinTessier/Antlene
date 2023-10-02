const std = @import("std");
const win32 = struct {
    usingnamespace @import("std").os.windows;
    usingnamespace @import("std").os.windows.user32;
};

pub const WM_RESHAPE = win32.WM_USER + 0;
pub const WM_ACTIVE = win32.WM_USER + 1;

pub extern fn GetModuleHandleA(?win32.LPCSTR) win32.HINSTANCE;
pub fn getModuleHandle(lpcstr: ?win32.LPCSTR) win32.HINSTANCE {
    return GetModuleHandleA(lpcstr);
}

pub extern "user32" fn ValidateRect(hwnd: win32.HWND, lpRect: ?*win32.RECT) win32.BOOL;
pub fn validateRect(hwnd: win32.HWND, lpRect: ?*win32.RECT) bool {
    const value = ValidateRect(hwnd, lpRect);
    return value == win32.TRUE;
}

pub extern "user32" fn PostMessageA(hwnd: win32.HWND, msg: win32.UINT, wParam: win32.WPARAM, lParam: win32.LPARAM) win32.BOOL;
pub fn postMessageA(hwnd: win32.HWND, msg: win32.UINT, wParam: win32.WPARAM, lParam: win32.LPARAM) bool {
    const value = PostMessageA(hwnd, msg, wParam, lParam);
    return value == win32.TRUE;
}

pub extern "user32" fn GetClientRect(hwnd: win32.HWND, lpRect: *win32.RECT) win32.BOOL;
pub fn getClientRect(hwnd: win32.HWND, lpRect: *win32.RECT) bool {
    return GetClientRect(hwnd, lpRect) != 0;
}

pub extern "user32" fn GetWindowRect(hwnd: win32.HWND, lpRect: *win32.RECT) win32.BOOL;
pub fn getWindowRect(hwnd: win32.HWND, lpRect: *win32.RECT) bool {
    return GetWindowRect(hwnd, lpRect) != 0;
}

pub fn loWord(x: isize) i16 {
    @setRuntimeSafety(false);
    return @intCast(x & 0xffff);
}

pub fn hiWord(x: isize) i16 {
    @setRuntimeSafety(false);
    return @intCast((x >> 16) & 0xffff);
}

pub const HGDIOBJ = *opaque {};
pub const BLACK_BRUSH: i32 = 4;

pub extern "gdi32" fn GetStockObject(i: i32) ?HGDIOBJ;
pub fn getStockObject(i: i32) ?HGDIOBJ {
    return GetStockObject(i);
}

pub extern "gdi32" fn ChoosePixelFormat(hdc: ?win32.HDC, ppfd: *const PIXELFORMATDESCRIPTOR) i32;
pub fn choosePixelFormat(hdc: ?win32.HDC, ppfd: *const PIXELFORMATDESCRIPTOR) i32 {
    var res = ChoosePixelFormat(hdc, ppfd);
    if (res == 0) {
        @panic("ChoosePixelFormat failed");
    }
    return res;
}

pub extern "gdi32" fn SetPixelFormat(hdc: ?win32.HDC, iPixelFormat: i32, ppfd: *const PIXELFORMATDESCRIPTOR) win32.BOOL;
pub fn setPixelFormat(hdc: ?win32.HDC, iPixelFormat: i32, ppfd: *const PIXELFORMATDESCRIPTOR) bool {
    return SetPixelFormat(hdc, iPixelFormat, ppfd) == win32.TRUE;
}

pub extern "gdi32" fn DescribePixelFormat(hdc: ?win32.HDC, iPixelFormat: i32, nBytes: u32, ppfd: *PIXELFORMATDESCRIPTOR) i32;
pub fn describePixelFormat(hdc: ?win32.HDC, iPixelFormat: i32, nBytes: u32, ppfd: *PIXELFORMATDESCRIPTOR) i32 {
    var res = DescribePixelFormat(hdc, iPixelFormat, nBytes, ppfd);
    if (res == 0) {
        @panic("DescribePixelFormat failed");
    }
    return res;
}

pub extern "gdi32" fn SwapBuffers(hdc: ?win32.HDC) win32.BOOL;
pub fn swapBuffers(hdc: ?win32.HDC) bool {
    return SwapBuffers(hdc) == win32.TRUE;
}

pub extern "gdi32" fn wglGetProcAddress(lpszProc: ?[*:0]const u8) ?*anyopaque;
pub fn glGetProcAddress(comptime T: type, lpszProc: ?[*:0]const u8) ?T {
    var ptr = wglGetProcAddress(lpszProc);
    if (ptr == null) {
        return null;
    }
    return @ptrCast(ptr);
}

pub extern "gdi32" fn wglCreateContext(hdc: ?win32.HDC) ?win32.HGLRC;
pub fn glCreateContext(hdc: ?win32.HDC) ?win32.HGLRC {
    return wglCreateContext(hdc);
}

pub extern "gdi32" fn wglDeleteContext(hglrc: ?win32.HGLRC) win32.BOOL;
pub fn glDeleteContext(hglrc: ?win32.HGLRC) bool {
    return wglDeleteContext(hglrc) == win32.TRUE;
}

pub extern "gdi32" fn wglMakeCurrent(hdc: ?win32.HDC, hglrc: ?win32.HGLRC) win32.BOOL;
pub fn glMakeCurrent(hdc: ?win32.HDC, hglrc: ?win32.HGLRC) bool {
    return wglMakeCurrent(hdc, hglrc) == win32.TRUE;
}

pub extern "winuser" fn ScreenToClient(hwnd: win32.HWND, lpPoint: *win32.POINT) win32.BOOL;
pub fn screenToClient(hwnd: ?*win32.HWND, lpPoint: *win32.POINT) bool {
    return ScreenToClient(hwnd, lpPoint) == win32.TRUE;
}

pub const PFD_TYPE_RGBA: win32.BYTE = 0;

pub const PFD_DRAW_TO_WINDOW: win32.DWORD = 0x00000004;
pub const PFD_SUPPORT_OPENGL: win32.DWORD = 0x00000020;
pub const PFD_DOUBLEBUFFER: win32.DWORD = 0x00000001;

pub const PFD_MAIN_PLANE: win32.BYTE = 0;

pub const PIXELFORMATDESCRIPTOR = extern struct {
    nSize: win32.WORD = 0,
    nVersion: win32.WORD = 0,
    dwFlags: win32.DWORD = 0,
    iPixelType: win32.BYTE = 0,
    cColorBits: win32.BYTE = 0,
    cRedBits: win32.BYTE = 0,
    cRedShift: win32.BYTE = 0,
    cGreenBits: win32.BYTE = 0,
    cGreenShift: win32.BYTE = 0,
    cBlueBits: win32.BYTE = 0,
    cBlueShift: win32.BYTE = 0,
    cAlphaBits: win32.BYTE = 0,
    cAlphaShift: win32.BYTE = 0,
    cAccumBits: win32.BYTE = 0,
    cAccumRedBits: win32.BYTE = 0,
    cAccumGreenBits: win32.BYTE = 0,
    cAccumBlueBits: win32.BYTE = 0,
    cAccumAlphaBits: win32.BYTE = 0,
    cDepthBits: win32.BYTE = 0,
    cStencilBits: win32.BYTE = 0,
    cAuxBuffers: win32.BYTE = 0,
    iLayerType: win32.BYTE = 0,
    bReserved: win32.BYTE = 0,
    dwLayerMask: win32.DWORD = 0,
    dwVisibleMask: win32.DWORD = 0,
    dwDamageMask: win32.DWORD = 0,
};
