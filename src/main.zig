const std = @import("std");
const g = @import("raylib");

const backgroud_color = g.Color{ .r = 236, .g = 236, .b = 223, .a = 255 };
const primary_color = g.Color{ .r = 17, .g = 17, .b = 17, .a = 255 };
const enemy_a_color = g.Color{ .r = 98, .g = 168, .b = 124, .a = 255 };
const enemy_b_color = g.Color{ .r = 241, .g = 135, .b = 1, .a = 255 };
const enemy_c_color = g.Color{ .r = 255, .g = 106, .b = 105, .a = 255 };
const enemy_default_color = g.Color{ .r = 189, .g = 196, .b = 204, .a = 255 };

const ScreenConfig = struct {
    width: i32 = 800,
    height: i32 = 800,

    pub fn update(self: *ScreenConfig, width: i32, height: i32) void {
        self.width = width;
        self.height = height;
    }
};

const Player = struct {
    position: g.Vector2,
    color: g.Color,
    size: f32,
    health: f32,

    pub fn damage(self: *Player) void {
        self.health = self.health - 1.0;
    }

    pub fn updatePosition(self: *Player, position: g.Vector2) void {
        self.position = position;
    }

    pub fn draw(self: Player, mouse_position: g.Vector2) void {
        // todo: where does the -90 degree offset come from? had to compensate
        const angle = std.math.atan2(mouse_position.y - self.position.y, mouse_position.x - self.position.x) + (90 * (std.math.pi / 180.0));

        g.DrawCircleV(self.position, self.size, self.color);

        const a = .{ .x = self.position.x, .y = self.position.y };
        const b = .{ .x = self.position.x, .y = self.position.y - self.size * 2.5 };
        const shift_soft = .{ .x = self.size / 3, .y = 0.0 };
        const shift_hard = .{ .x = self.size, .y = 0.0 };

        // calculate vectors
        const l_a = g.Vector2Subtract(a, shift_soft);
        const l_b = g.Vector2Subtract(b, shift_soft);
        const l_c = g.Vector2Subtract(a, shift_hard);
        const r_a = g.Vector2Add(a, shift_soft);
        const r_b = g.Vector2Add(b, shift_soft);
        const r_c = g.Vector2Add(a, shift_hard);

        // translate
        const t_l_a = g.Vector2Subtract(l_a, self.position);
        const t_l_b = g.Vector2Subtract(l_b, self.position);
        const t_l_c = g.Vector2Subtract(l_c, self.position);
        const t_r_a = g.Vector2Subtract(r_a, self.position);
        const t_r_b = g.Vector2Subtract(r_b, self.position);
        const t_r_c = g.Vector2Subtract(r_c, self.position);

        // rotate
        const r_l_a = g.Vector2Rotate(t_l_a, angle);
        const r_l_b = g.Vector2Rotate(t_l_b, angle);
        const r_l_c = g.Vector2Rotate(t_l_c, angle);
        const r_r_a = g.Vector2Rotate(t_r_a, angle);
        const r_r_b = g.Vector2Rotate(t_r_b, angle);
        const r_r_c = g.Vector2Rotate(t_r_c, angle);

        // translate back
        const f_l_a = g.Vector2Add(r_l_a, self.position);
        const f_l_b = g.Vector2Add(r_l_b, self.position);
        const f_l_c = g.Vector2Add(r_l_c, self.position);
        const f_r_a = g.Vector2Add(r_r_a, self.position);
        const f_r_b = g.Vector2Add(r_r_b, self.position);
        const f_r_c = g.Vector2Add(r_r_c, self.position);

        g.DrawTriangle(f_l_a, f_l_b, f_l_c, self.color);
        g.DrawTriangle(f_r_a, f_r_c, f_r_b, self.color);

        // draw damage
        g.DrawCircleV(self.position, self.size - self.health, g.RED);
    }
};

const Enemy = struct {
    position: g.Vector2,
    speed: g.Vector2,
    size: f32,
    color: g.Color,

    pub fn update(self: *Enemy) void {
        self.position = self.position.add(self.speed);
    }

    pub fn draw(self: Enemy) void {
        g.DrawCircleV(self.position, self.size + 2.0, self.color);
        g.DrawCircleV(self.position, self.size, primary_color);
    }
};

const Bullet = struct {
    position: g.Vector2,
    speed: g.Vector2,

    pub fn update(self: *Bullet) void {
        self.position = self.position.add(self.speed);
    }

    pub fn draw(self: Bullet) void {
        g.DrawCircleV(self.position, 3.0, primary_color);
    }
};

fn createEnemy(target: g.Vector2, enemies: *std.ArrayList(Enemy)) !void {
    const circum_pos = @as(f32, @floatFromInt(g.GetRandomValue(0, 360)));
    const distancing = @as(f32, @floatFromInt(g.GetRandomValue(800, 1200)));
    const x = target.x + distancing * std.math.cos(circum_pos);
    const y = target.y + distancing * std.math.sin(circum_pos);
    const angle = std.math.atan2(target.y - y, target.x - x);
    const vx = 1.0 * std.math.cos(angle);
    const vy = 1.0 * std.math.sin(angle);

    try enemies.append(Enemy{
        .position = .{
            .x = x,
            .y = y,
        },
        .speed = .{
            .x = vx,
            .y = vy,
        },
        .size = @as(f32, @floatFromInt(g.GetRandomValue(3, 7))),
        .color = switch (g.GetRandomValue(1, 3)) {
            1 => enemy_a_color,
            2 => enemy_b_color,
            3 => enemy_c_color,
            else => enemy_default_color,
        },
    });
}

fn createBullet(start: g.Vector2, target: g.Vector2, bullets: *std.ArrayList(Bullet)) !void {
    const angle = std.math.atan2(target.y - start.y, target.x - start.x);
    const vx = 1.5 * std.math.cos(angle);
    const vy = 1.5 * std.math.sin(angle);

    try bullets.append(Bullet{
        .position = start,
        .speed = .{
            .x = vx,
            .y = vy,
        },
    });
}

pub fn main() !void {
    var config = ScreenConfig{};

    // init window
    g.SetConfigFlags(g.ConfigFlags{
        .FLAG_WINDOW_RESIZABLE = false,
        .FLAG_WINDOW_UNDECORATED = true,
        .FLAG_MSAA_4X_HINT = true,
    });
    g.SetTargetFPS(144);
    g.InitWindow(config.width, config.height, "gundling");
    defer g.CloseWindow();

    // init player and it's position centered
    //  * can change on window resize
    var player = Player{
        .position = .{
            .x = @as(f32, @floatFromInt(@divTrunc(g.GetScreenWidth(), 2))),
            .y = @as(f32, @floatFromInt(@divTrunc(g.GetScreenHeight(), 2))),
        },
        .color = primary_color,
        .size = 14.0,
        .health = 14.0,
    };

    // boundaries of the screen used to check if bullets are out of screen
    //  * can change on window resize
    var boundaries = g.Rectangle{
        .x = 0,
        .y = 0,
        .width = @as(f32, @floatFromInt(g.GetScreenWidth())),
        .height = @as(f32, @floatFromInt(g.GetScreenHeight())),
    };

    var enemies = std.ArrayList(Enemy).init(std.heap.c_allocator);
    defer enemies.deinit();

    var bullets = std.ArrayList(Bullet).init(std.heap.c_allocator);
    defer bullets.deinit();

    // main loop
    var park_time = g.GetTime();
    while (!g.WindowShouldClose()) {

        // updates on window resized event
        if (g.IsWindowResized() and !g.IsWindowFullscreen()) {
            const width = g.GetScreenWidth();
            const height = g.GetScreenHeight();
            config.update(width, height);
            player.updatePosition(.{
                .x = @as(f32, @floatFromInt(@divTrunc(width, 2))),
                .y = @as(f32, @floatFromInt(@divTrunc(height, 2))),
            });
            boundaries = g.Rectangle{
                .x = 0,
                .y = 0,
                .width = @as(f32, @floatFromInt(width)),
                .height = @as(f32, @floatFromInt(height)),
            };

            bullets.clearAndFree();
            enemies.clearAndFree();
        }

        // create bullets on left mouse click (on release)
        if (g.IsMouseButtonReleased(.MOUSE_BUTTON_LEFT)) {
            try createBullet(player.position, g.GetMousePosition(), &bullets);
        }

        // calculations before the rendering

        // collisions
        for (enemies.items, 0..) |enemy, ei| {

            // first check collisions with bullets, you can destroy enemies with bullets
            for (bullets.items, 0..) |bullet, bi| {
                if (g.CheckCollisionCircles(bullet.position, 1.0, enemy.position, enemy.size)) {
                    _ = bullets.orderedRemove(bi);
                    _ = enemies.orderedRemove(ei);
                }
            }

            // second check for enemies and player colission that results in damage to the player
            if (g.CheckCollisionCircles(enemy.position, enemy.size, player.position, player.size)) {
                player.damage();
                _ = enemies.orderedRemove(ei);
            }
        }

        // clear bullets if they are out of screen
        for (bullets.items, 0..) |bullet, b_index| {
            if (!g.CheckCollisionCircleRec(bullet.position, 1.0, boundaries)) {
                _ = bullets.orderedRemove(b_index);
                continue;
            }
        }

        // game over logic and graceful break
        if (player.health <= 0.0) break;

        // update timer
        if (g.GetTime() - park_time > 1.0) {
            park_time = g.GetTime();
            try createEnemy(player.position, &enemies);
        }

        for (enemies.items) |*enemy| enemy.update();
        for (bullets.items) |*bullet| bullet.update();

        g.BeginDrawing();
        defer g.EndDrawing();
        g.ClearBackground(backgroud_color);

        const fps_text = try g.TextFormat(std.heap.c_allocator, "{d} FPS", .{g.GetFPS()});
        g.DrawText(fps_text, 10, 10, 20, g.ORANGE);

        player.draw(g.GetMousePosition());
        for (enemies.items) |enemy| enemy.draw();
        for (bullets.items) |bullet| bullet.draw();
    }
}
