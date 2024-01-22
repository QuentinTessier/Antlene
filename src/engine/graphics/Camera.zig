const std = @import("std");
const Math = @import("AntleneMath");

pub const FlyingCamera = struct {
    const Direction = enum {
        Forward,
        Backward,
        Left,
        Right,
    };

    position: @Vector(3, f32),
    front: @Vector(3, f32),
    up: @Vector(3, f32),
    right: @Vector(3, f32),
    worldUp: @Vector(3, f32),

    yaw: f32,
    pitch: f32,

    fovy: f32,
    near: f32,
    far: f32,
    aspect_ratio: f32,

    isDirty: bool = true,

    pub fn init(
        position: @Vector(3, f32),
        up: @Vector(3, f32),
        front: @Vector(3, f32),
        yaw: f32,
        pitch: f32,
        fovy: f32,
        near: f32,
        far: f32,
        aspect_ratio: f32,
    ) FlyingCamera {
        var camera = FlyingCamera{
            .position = position,
            .front = front,
            .worldUp = up,
            .right = .{ 0, 0, 0 },
            .up = .{ 0, 0, 0 },
            .yaw = yaw,
            .pitch = pitch,
            .fovy = fovy,
            .near = near,
            .far = far,
            .aspect_ratio = aspect_ratio,
        };
        camera.updateVectors();
        return camera;
    }

    pub fn updateVectors(self: *FlyingCamera) void {
        self.front = Math.Vec3.normalize(Math.Vec3.init(.{
            .x = Math.cos(Math.degreesToRadians(f32, self.yaw)) * Math.cos(Math.degreesToRadians(f32, self.pitch)),
            .y = Math.sin(Math.degreesToRadians(f32, self.pitch)),
            .z = Math.sin(Math.degreesToRadians(f32, self.yaw)) * Math.cos(Math.degreesToRadians(f32, self.pitch)),
        }));
        self.right = Math.Vec3.normalize(Math.Vec3.cross(self.front, self.worldUp));
        self.up = Math.Vec3.normalize(Math.Vec3.cross(self.right, self.front));
        self.isDirty = false;
    }

    pub fn getViewMatrix(self: FlyingCamera) Math.mat4x4 {
        return Math.lookAt(self.position, self.position + self.front, self.up);
    }

    pub fn getProjectionMatrix(self: FlyingCamera) Math.mat4x4 {
        return Math.perspective(Math.degreesToRadians(f32, self.fovy), self.aspect_ratio, self.near, self.far);
    }

    pub fn translate(self: *FlyingCamera, dir: Direction, velocity: f32) void {
        const vel = Math.Vec3.splat(velocity);
        switch (dir) {
            .Forward => {
                self.position += self.front * vel;
            },
            .Backward => {
                self.position -= self.front * vel;
            },
            .Left => {
                self.position -= self.right * vel;
            },
            .Right => {
                self.position += self.right * vel;
            },
        }
        self.isDirty = true;
    }

    pub fn lookAngles(self: *FlyingCamera, xOffset: f32, yOffset: f32) void {
        self.yaw += xOffset;
        self.pitch += yOffset;

        if (self.pitch > 85.9) {
            self.pitch = 85.0;
        } else if (self.pitch < -85.9) {
            self.pitch = -85.0;
        }
        self.isDirty = true;
    }
};
