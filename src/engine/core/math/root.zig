const std = @import("std");

pub const VectorGenerator = @import("Vector.zig").Vector;
pub const MatrixGenerator = @import("Mat.zig").MatrixGenerator;

pub const Vec2 = VectorGenerator(2, f32);
pub const vec2 = Vec2.SIMDType;
pub const Vec3 = VectorGenerator(3, f32);
pub const vec3 = Vec3.SIMDType;
pub const Vec4 = VectorGenerator(4, f32);
pub const vec4 = Vec4.SIMDType;
pub const Mat2x2 = MatrixGenerator(2, 2, f32);
pub const mat2x2 = Mat2x2.MatrixType;
pub const Mat3x3 = MatrixGenerator(3, 3, f32);
pub const mat3x3 = Mat3x3.MatrixType;
pub const Mat4x4 = MatrixGenerator(4, 4, f32);
pub const mat4x4 = Mat4x4.MatrixType;

pub const Vec2h = VectorGenerator(2, f16);
pub const Vec3h = VectorGenerator(3, f16);
pub const Vec4h = VectorGenerator(4, f16);
pub const Mat2x2h = MatrixGenerator(2, 2, f16);
pub const Mat3x3h = MatrixGenerator(3, 3, f16);
pub const Mat4x4h = MatrixGenerator(4, 4, f16);

pub const Vec2d = VectorGenerator(2, f64);
pub const Vec3d = VectorGenerator(3, f64);
pub const Vec4d = VectorGenerator(4, f64);
pub const Mat2x2d = MatrixGenerator(2, 2, f64);
pub const Mat3x3d = MatrixGenerator(3, 3, f64);
pub const Mat4x4d = MatrixGenerator(4, 4, f64);

pub const Rotor = @import("Rotor.zig").Rotor;

// Constants
pub const pi = std.math.pi;
pub const two_sqrtpi = std.math.two_sqrtpi;
pub const sqrt2 = std.math.sqrt2;
pub const sqrt1_2 = std.math.sqrt1_2;

pub const eql = std.math.approxEqAbs;
pub const eps = std.math.floatEps;
pub const eps_f16 = std.math.floatEps(f16);
pub const eps_f32 = std.math.floatEps(f32);
pub const eps_f64 = std.math.floatEps(f64);
pub const nan_f16 = std.math.nan(f16);
pub const nan_f32 = std.math.nan(f32);
pub const nan_f64 = std.math.nan(f64);

pub const inf = std.math.inf;
pub const sqrt = std.math.sqrt;
pub const sin = std.math.sin;
pub const cos = std.math.cos;
pub const tan = std.math.tan;
pub const isNan = std.math.isNan;
pub const isInf = std.math.isInf;
pub const clamp = std.math.clamp;
pub const log10 = std.math.log10;
pub const degreesToRadians = std.math.degreesToRadians;
pub const radiansToDegrees = std.math.radiansToDegrees;
