const std = @import("std");
const win32 = struct {
    usingnamespace @import("std").os.windows;
};

pub const WM_RESHAPE = WM_USER + 0;
pub const WM_ACTIVE = WM_USER + 1;

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

pub extern "user32" fn ScreenToClient(hwnd: win32.HWND, lpPoint: *win32.POINT) win32.BOOL;
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

pub const WNDPROC = *const fn (win32.HWND, win32.UINT, win32.WPARAM, win32.LPARAM) callconv(win32.WINAPI) win32.LRESULT;

pub const WNDCLASSEXA = extern struct {
    cbSize: win32.UINT,
    style: win32.UINT,
    lpfnWndProc: WNDPROC,
    cbClsExtra: win32.INT,
    cbWndExtra: win32.INT,
    hInstance: win32.HINSTANCE,
    hIcon: ?win32.HICON,
    hCursor: ?win32.HCURSOR,
    hbrBackground: ?win32.HBRUSH,
    lpszMenuName: ?win32.LPCSTR,
    lpszClassName: win32.LPCSTR,
    hIconSm: ?win32.HICON,
};

pub extern "user32" fn GetDC(win32.HWND) callconv(win32.WINAPI) ?win32.HDC;
pub extern "user32" fn ReleaseDC(win32.HWND, win32.HDC) callconv(win32.WINAPI) c_int;

pub extern var DefWindowProcA: WNDPROC;

pub const CW_USEDEFAULT: i32 = @bitCast(@as(u32, 0x80000000));

extern "user32" fn RegisterClassExA(*const WNDCLASSEXA) callconv(win32.WINAPI) win32.ATOM;
pub fn registerClassExA(class: *const WNDCLASSEXA) win32.ATOM {
    return RegisterClassExA(class);
}

//   [in]           DWORD     dwExStyle,
//   [in, optional] LPCSTR    lpClassName,
//   [in, optional] LPCSTR    lpWindowName,
//   [in]           DWORD     dwStyle,
//   [in]           int       X,
//   [in]           int       Y,
//   [in]           int       nWidth,
//   [in]           int       nHeight,
//   [in, optional] HWND      hWndParent,
//   [in, optional] HMENU     hMenu,
//   [in, optional] HINSTANCE hInstance,
//   [in, optional] LPVOID    lpParam

extern "user32" fn CreateWindowExA(
    dwExStyle: win32.DWORD,
    lpClassName: ?win32.LPCSTR,
    lpWindowName: ?win32.LPCSTR,
    dwStyle: win32.DWORD,
    X: c_int,
    Y: c_int,
    nWidth: c_int,
    nHeight: c_int,
    hWndParent: ?win32.HWND,
    hMenu: ?win32.HMENU,
    hInstance: ?win32.HINSTANCE,
    lpParam: ?win32.LPVOID,
) callconv(win32.WINAPI) win32.HWND;
pub fn createWindowExA(
    dwExStyle: win32.DWORD,
    lpClassName: ?win32.LPCSTR,
    lpWindowName: ?win32.LPCSTR,
    dwStyle: win32.DWORD,
    X: c_int,
    Y: c_int,
    nWidth: c_int,
    nHeight: c_int,
    hWndParent: ?win32.HWND,
    hMenu: ?win32.HMENU,
    hInstance: ?win32.HINSTANCE,
    lpParam: ?win32.LPVOID,
) win32.HWND {
    return CreateWindowExA(
        dwExStyle,
        lpClassName,
        lpWindowName,
        dwStyle,
        X,
        Y,
        nWidth,
        nHeight,
        hWndParent,
        hMenu,
        hInstance,
        lpParam,
    );
}

extern "user32" fn DestroyWindow(win32.HWND) callconv(win32.WINAPI) win32.BOOL;
pub fn destroyWindow(hwnd: win32.HWND) bool {
    const res = DestroyWindow(hwnd);
    return if (res != 0) true else false;
}

extern "user32" fn ShowWindow(win32.HWND, c_int) callconv(win32.WINAPI) win32.BOOL;
pub fn showWindow(hwnd: win32.HWND, nCmdShow: c_int) bool {
    const res = ShowWindow(hwnd, nCmdShow);
    return if (res != 0) true else false;
}

extern "user32" fn PostQuitMessage(c_int) callconv(win32.WINAPI) void;
pub fn postQuitMessage(nExitCode: c_int) void {
    PostQuitMessage(nExitCode);
}

extern "user32" fn PeekMessageA(*MSG, ?win32.HWND, win32.UINT, win32.UINT, win32.UINT) callconv(win32.WINAPI) win32.BOOL;
pub fn peekMessageA(msg: *MSG, hwnd: ?win32.HWND, wMsgFilterMin: win32.UINT, wMsgFilterMax: win32.UINT, wRemoveMsg: win32.UINT) bool {
    var res = PeekMessageA(msg, hwnd, wMsgFilterMin, wMsgFilterMax, wRemoveMsg);
    return if (res == 1) true else false;
}

extern "user32" fn DispatchMessageA(*MSG) callconv(win32.WINAPI) win32.LRESULT;
pub fn dispatchMessageA(msg: *MSG) win32.LRESULT {
    return DispatchMessageA(msg);
}

extern "user32" fn TranslateMessage(*MSG) callconv(win32.WINAPI) win32.BOOL;
pub fn translateMessage(msg: *MSG) bool {
    var res = TranslateMessage(msg);
    return (res == 1);
}

pub const MSG = extern struct {
    hWnd: ?win32.HWND,
    message: win32.UINT,
    wParam: win32.WPARAM,
    lParam: win32.LPARAM,
    time: win32.DWORD,
    pt: win32.POINT,
    lPrivate: win32.DWORD,
};

pub const SW_HIDE = 0;
pub const SW_SHOWNORMAL = 1;
pub const SW_NORMAL = 1;
pub const SW_SHOWMINIMIZED = 2;
pub const SW_SHOWMAXIMIZED = 3;
pub const SW_MAXIMIZE = 3;
pub const SW_SHOWNOACTIVATE = 4;
pub const SW_SHOW = 5;
pub const SW_MINIMIZE = 6;
pub const SW_SHOWMINNOACTIVE = 7;
pub const SW_SHOWNA = 8;
pub const SW_RESTORE = 9;
pub const SW_SHOWDEFAULT = 10;
pub const SW_FORCEMINIMIZE = 11;

pub const CS_BYTEALIGNCLIENT = 0x1000;
pub const CS_BYTEALIGNWINDOW = 0x2000;
pub const CS_CLASSDC = 0x0040;
pub const CS_DBLCLKS = 0x0008;
pub const CS_DROPSHADOW = 0x00020000;
pub const CS_GLOBALCLASS = 0x4000;
pub const CS_HREDRAW = 0x0002;
pub const CS_NOCLOSE = 0x0200;
pub const CS_OWNDC = 0x0020;
pub const CS_PARENTDC = 0x0080;
pub const CS_SAVEBITS = 0x0800;
pub const CS_VREDRAW = 0x0001;

pub const WS_BORDER = 0x00800000;
pub const WS_CAPTION = 0x00C0000;
pub const WS_CHILD = 0x40000000;
pub const WS_CHILDWINDOW = 0x40000000;
pub const WS_CLIPCHILDREN = 0x02000000;
pub const WS_CLIPSIBLINGS = 0x04000000;
pub const WS_DISABLED = 0x08000000;
pub const WS_DLGFRAME = 0x00400000;
pub const WS_GROUP = 0x00020000;
pub const WS_HSCROLL = 0x00100000;
pub const WS_ICONIC = 0x20000000;
pub const WS_MAXIMIZE = 0x01000000;
pub const WS_MAXIMIZEBOX = 0x00010000;
pub const WS_MINIMIZE = 0x20000000;
pub const WS_MINIMIZEBOX = 0x00020000;
pub const WS_OVERLAPPED = 0x00000000;
pub const WS_OVERLAPPEDWINDOW = (WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU | WS_THICKFRAME | WS_MINIMIZEBOX | WS_MAXIMIZEBOX);
pub const WS_POPUP = 0x80000000;
pub const WS_POPUPWINDOW = (WS_POPUP | WS_BORDER | WS_SYSMENU);
pub const WS_SIZEBOX = 0x00040000;
pub const WS_SYSMENU = 0x00080000;
pub const WS_TABSTOP = 0x00010000;
pub const WS_THICKFRAME = 0x00040000;
pub const WS_TILED = 0x00000000;
pub const WS_TILEDWINDOW = (WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU | WS_THICKFRAME | WS_MINIMIZEBOX | WS_MAXIMIZEBOX);
pub const WS_VISIBLE = 0x10000000;
pub const WS_VSCROLL = 0x00200000;

pub const WM_NULL = 0x0000;
pub const WM_CREATE = 0x0001;
pub const WM_DESTROY = 0x0002;
pub const WM_MOVE = 0x0003;
pub const WM_SIZE = 0x0005;
pub const WM_USER = 0x0400;

pub const WM_ACTIVATE = 0x0006;

pub const WA_INACTIVE = 0;
pub const WA_ACTIVE = 1;
pub const WA_CLICKACTIVE = 2;

pub const WM_SETFOCUS = 0x0007;
pub const WM_KILLFOCUS = 0x0008;
pub const WM_ENABLE = 0x000A;
pub const WM_SETREDRAW = 0x000B;
pub const WM_SETTEXT = 0x000C;
pub const WM_GETTEXT = 0x000D;
pub const WM_GETTEXTLENGTH = 0x000E;
pub const WM_PAINT = 0x000F;
pub const WM_CLOSE = 0x0010;
pub const WM_QUIT = 0x0012;
pub const WM_ERASEBKGND = 0x0014;
pub const WM_SYSCOLORCHANGE = 0x0015;
pub const WM_SHOWWINDOW = 0x0018;
pub const WM_WININICHANGE = 0x001A;

pub const WM_EXITSIZEMOVE = 0x0232;

pub const WM_KEYDOWN = 0x0100;
pub const WM_KEYUP = 0x0101;

pub const WM_MOUSEMOVE = 0x0200;
pub const WM_LBUTTONDOWN = 0x0201;
pub const WM_LBUTTONUP = 0x0202;
pub const WM_MBUTTONDOWN = 0x0207;
pub const WM_MBUTTONUP = 0x0208;
pub const WM_RBUTTONDOWN = 0x0204;
pub const WM_RBUTTONUP = 0x0205;
pub const WM_MOUSEWHEEL = 0x020A;

pub const PM_NOREMOVE = 0x0000;
pub const PM_REMOVE = 0x0001;
pub const PM_NOYIELD = 0x0002;
