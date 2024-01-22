pub const Api = enum {
    OpenGL,
};

pub const GraphicContext = switch (Api.OpenGL) {
    inline .OpenGL => @import("gl/Context.zig"),
};
