pub const packages = struct {
    pub const @"N-V-__8AABHMqAWYuRdIlflwi8gksPnlUMQBiSxAqQAAZFms" = struct {
        pub const available = false;
    };
    pub const @"N-V-__8AAEp9UgBJ2n1eks3_3YZk3GCO1XOENazWaCO7ggM2" = struct {
        pub const build_root = "/home/nbardavi/.cache/zig/p/N-V-__8AAEp9UgBJ2n1eks3_3YZk3GCO1XOENazWaCO7ggM2";
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"N-V-__8AALRTBQDo_pUJ8IQ-XiIyYwDKQVwnr7-7o5kvPDGE" = struct {
        pub const available = false;
    };
    pub const @"raylib-5.5.0-whq8uFV0zQA9NXxhpYFZk_yHW6xzg5eKGmOtMJ2DOTdU" = struct {
        pub const build_root = "/home/nbardavi/.cache/zig/p/raylib-5.5.0-whq8uFV0zQA9NXxhpYFZk_yHW6xzg5eKGmOtMJ2DOTdU";
        pub const build_zig = @import("raylib-5.5.0-whq8uFV0zQA9NXxhpYFZk_yHW6xzg5eKGmOtMJ2DOTdU");
        pub const deps: []const struct { []const u8, []const u8 } = &.{
            .{ "xcode_frameworks", "N-V-__8AABHMqAWYuRdIlflwi8gksPnlUMQBiSxAqQAAZFms" },
            .{ "emsdk", "N-V-__8AALRTBQDo_pUJ8IQ-XiIyYwDKQVwnr7-7o5kvPDGE" },
        };
    };
    pub const @"raylib_zig-5.6.0-dev-KE8REBMyBQCnQ9RBhHsoSKr97XmDHF84wx3g0UiMRDxj" = struct {
        pub const build_root = "/home/nbardavi/.cache/zig/p/raylib_zig-5.6.0-dev-KE8REBMyBQCnQ9RBhHsoSKr97XmDHF84wx3g0UiMRDxj";
        pub const build_zig = @import("raylib_zig-5.6.0-dev-KE8REBMyBQCnQ9RBhHsoSKr97XmDHF84wx3g0UiMRDxj");
        pub const deps: []const struct { []const u8, []const u8 } = &.{
            .{ "raylib", "raylib-5.5.0-whq8uFV0zQA9NXxhpYFZk_yHW6xzg5eKGmOtMJ2DOTdU" },
            .{ "raygui", "N-V-__8AAEp9UgBJ2n1eks3_3YZk3GCO1XOENazWaCO7ggM2" },
        };
    };
};

pub const root_deps: []const struct { []const u8, []const u8 } = &.{
    .{ "raylib_zig", "raylib_zig-5.6.0-dev-KE8REBMyBQCnQ9RBhHsoSKr97XmDHF84wx3g0UiMRDxj" },
};
