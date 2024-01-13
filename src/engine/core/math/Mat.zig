const std = @import("std");

pub fn MatrixGenerator(comptime Row: comptime_int, comptime Column: comptime_int, comptime T: type) type {
    return struct {
        pub const MatrixType = [Column]@Vector(Row, T);

        pub fn identity() MatrixType {
            var mat: MatrixType = undefined;
            comptime var offset = 0;
            inline for (0..Column) |y| {
                inline for (0..Row) |x| {
                    mat[y][x] = if (x == offset) 1 else 0;
                }
                offset += 1;
            }
            return mat;
        }

        pub fn init(m: [Column][Row]T) MatrixType {
            var mat: MatrixType = undefined;
            comptime var current = 0;
            inline for (0..Column) |y| {
                var r: [Row]T = undefined;
                inline for (0..Row) |x| {
                    r[x] = m[x][current];
                }
                mat[y] = r;
                current += 1;
            }
            return mat;
        }

        pub fn column(m: MatrixType, i: usize) @Vector(Column, T) {
            return m[i];
        }

        pub fn row(m: MatrixType, i: usize) @Vector(Row, T) {
            var array: [Row]T = undefined;
            inline for (0..Row) |index| {
                array[index] = m[index][i];
            }
            return array;
        }

        pub fn transpose(m: MatrixType) MatrixGenerator(Column, Row, T).MatrixType {
            var new: MatrixGenerator(Column, Row, T).MatrixType = undefined;
            inline for (0..Column) |y| {
                new[y] = row(m, y);
            }
            return new;
        }

        pub fn mul(m1: MatrixType, m2: MatrixType) MatrixType {
            @setEvalBranchQuota(100000);
            var result: MatrixType = undefined;
            inline for (0..Row) |r| {
                inline for (0..Column) |c| {
                    var sum: T = 0;
                    inline for (0..Row) |i| {
                        sum += m1[i][r] * m2[c][i];
                    }
                    result[c][r] = sum;
                }
            }
            return result;
        }

        pub fn mulVec(m: MatrixType, v: @Vector(Column, T)) @Vector(Column, T) {
            var result: @Vector(Column, T) = @splat(0);
            inline for (0..Row) |r| {
                inline for (0..Column) |i| {
                    result[i] += m[r][i] * v[r];
                }
            }
            return result;
        }

        const TotalSize = Row * Column;

        pub fn scale(v: @Vector(Column - 1, T)) MatrixType {
            const s = @as([Column - 1]T, v) ++ [1]T{1};
            var mat: MatrixType = undefined;
            comptime var offset = 0;
            inline for (0..Column) |y| {
                inline for (0..Row) |x| {
                    mat[y][x] = if (x == offset) s[offset] else 0;
                }
                offset += 1;
            }
            return mat;
        }

        pub fn translate(v: @Vector(Row - 1, T)) MatrixType {
            const t = @as([Column - 1]T, v) ++ [1]T{1};
            var mat = identity();
            mat[Column - 1] = t;
            return mat;
        }

        pub usingnamespace if (Row == 4 and Column == 4) struct {
            pub fn rotateX(radians: T) MatrixType {
                const c = std.math.cos(radians);
                const s = std.math.sin(radians);
                return init(.{
                    .{ 1, 0, 0, 0 },
                    .{ 0, c, -s, 0 },
                    .{ 0, s, c, 0 },
                    .{ 0, 0, 0, 1 },
                });
            }

            pub fn rotateY(radians: T) MatrixType {
                const c = std.math.cos(radians);
                const s = std.math.sin(radians);
                return init(.{
                    .{ c, 0, s, 0 },
                    .{ 0, 1, 0, 0 },
                    .{ -s, 0, c, 0 },
                    .{ 0, 0, 0, 1 },
                });
            }

            pub fn rotateZ(radians: T) MatrixType {
                const c = std.math.cos(radians);
                const s = std.math.sin(radians);
                return init(.{
                    .{ c, -s, 0, 0 },
                    .{ s, c, 0, 0 },
                    .{ 0, 0, 1, 0 },
                    .{ 0, 0, 0, 1 },
                });
            }
        } else struct {};
    };
}
