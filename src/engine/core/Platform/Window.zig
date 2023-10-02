const std = @import("std");
const builtin = @import("builtin");

pub const WindowExtent = struct { width: u32, height: u32 };

pub const KeyCode = enum(u32) {
    NONE = 0, // Undefined. (No event)
    A = 4,
    B = 5,
    C = 6,
    D = 7,
    E = 8,
    F = 9,
    G = 10,
    H = 11,
    I = 12,
    J = 13,
    K = 14,
    L = 15,
    M = 16,
    N = 17,
    O = 18,
    P = 19,
    Q = 20,
    R = 21,
    S = 22,
    T = 23,
    U = 24,
    V = 25,
    W = 26,
    X = 27,
    Y = 28,
    Z = 29,
    _1 = 30, // 1 and !
    _2 = 31, // 2 and @
    _3 = 32, // 3 and #
    _4 = 33, // 4 and $
    _5 = 34, // 5 and %
    _6 = 35, // 6 and ^
    _7 = 36, // 7 and &
    _8 = 37, // 8 and *
    _9 = 38, // 9 and (
    _0 = 39, // 0 and )
    Enter = 40, // (Return)
    Escape = 41,
    Delete = 42,
    Tab = 43,
    Space = 44,
    Minus = 45, // - and (underscore)
    Equals = 46, // = and +
    LeftBracket = 47, // [ and {
    RightBracket = 48, // ] and }
    Backslash = 49, // \ and |
    // NonUSHash     = 50, // # and ~
    Semicolon = 51, // ; and :
    Quote = 52, // ' and "
    Grave = 53,
    Comma = 54, // , and <
    Period = 55, // . and >
    Slash = 56, // / and ?
    CapsLock = 57,
    F1 = 58,
    F2 = 59,
    F3 = 60,
    F4 = 61,
    F5 = 62,
    F6 = 63,
    F7 = 64,
    F8 = 65,
    F9 = 66,
    F10 = 67,
    F11 = 68,
    F12 = 69,
    PrintScreen = 70,
    ScrollLock = 71,
    Pause = 72,
    Insert = 73,
    Home = 74,
    PageUp = 75,
    DeleteForward = 76,
    End = 77,
    PageDown = 78,
    Right = 79, // Right arrow
    Left = 80, // Left arrow
    Down = 81, // Down arrow
    Up = 82, // Up arrow
    KP_NumLock = 83,
    KP_Divide = 84,
    KP_Multiply = 85,
    KP_Subtract = 86,
    KP_Add = 87,
    KP_Enter = 88,
    KP_1 = 89,
    KP_2 = 90,
    KP_3 = 91,
    KP_4 = 92,
    KP_5 = 93,
    KP_6 = 94,
    KP_7 = 95,
    KP_8 = 96,
    KP_9 = 97,
    KP_0 = 98,
    KP_Point = 99, // . and Del
    KP_Equals = 103,
    F13 = 104,
    F14 = 105,
    F15 = 106,
    F16 = 107,
    F17 = 108,
    F18 = 109,
    F19 = 110,
    F20 = 111,
    F21 = 112,
    F22 = 113,
    F23 = 114,
    F24 = 115,
    // Help          = 117,
    Menu = 118,
    Mute = 127,
    VolumeUp = 128,
    VolumeDown = 129,
    LeftControl = 224, // WARNING : Android has no Ctrl keys.
    LeftShift = 225,
    LeftAlt = 226,
    LeftGUI = 227,
    RightControl = 228,
    RightShift = 229, // WARNING : Win32 fails to send a WM_KEYUP message if both shift keys are pressed, and one released.
    RightAlt = 230,
    RightGUI = 231,
};

pub const MouseButton = enum(u32) {
    Left,
    Middle,
    Right,
};

pub const WindowEvent = union(enum(u32)) {
    // Window events
    close: void,
    resize: struct { old: WindowExtent, new: WindowExtent },
    moved: struct { old: struct { x: i32, y: i32 }, new: struct { x: i32, y: i32 } },
    focus: bool,

    // Keyboard events
    keyDown: KeyCode,
    keyUp: KeyCode,
    keyRepeat: KeyCode,

    // Mouse events
    mouseMove: struct { x: i32, y: i32 },
    mouseDown: MouseButton,
    mouseUp: MouseButton,
    mouseScroll: f32,

    // Touch events
    touchDown: struct { id: u64, x: i32, y: i32 },
};

pub fn PlatformWindow() type {
    switch (builtin.os.tag) {
        .windows => {
            const Win32Window = @import("win32/Window.zig").Win32Window;
            return Win32Window;
        },
        .linux => @compileError("Linux platform is planned but not yet implemented"),
        else => @compileError("Window is not supported on this platform"),
    }
}

pub const Window = PlatformWindow();
