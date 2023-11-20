const std = @import("std");
const builtin = @import("builtin");
const AntleneWindowSystem = @import("AntleneWindowSystem");

const EventBus = @import("../EventHandling/EventBus.zig").EventBus;

pub const Window = AntleneWindowSystem.PlatfromWindow(EventBus);
pub const Events = AntleneWindowSystem.Events;

// TODO: Window should expose events
pub const CloseEvent = void;
