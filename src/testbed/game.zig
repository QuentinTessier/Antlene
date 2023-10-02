const std = @import("std");
const antlene = @import("antlene");

const TestbedApplicationInformation = antlene.ApplicationInformation{
    .name = "Testbed",
    .version = antlene.Version.make(0, 1, 0),
    .gameInit = &init,
};

pub fn getApplicationInformation() antlene.ApplicationInformation {
    return TestbedApplicationInformation;
}

pub fn init(app: *antlene.Application) anyerror!void {
    std.log.info("Init application {}.{}.{} !", .{ antlene.Version.getMajor(app.version), antlene.Version.getMinor(app.version), antlene.Version.getPatch(app.version) });
}
