package main

import "core:fmt"
import "core:math/linalg"
import "core:math/rand"
import "core:path/filepath"
import "core:strings"
import "vendor:raylib"

TILE_WIDTH :: 256
TILE_HEIGHT :: 128
TILE_FULL_HEIGHT :: 512

main :: proc() {
	raylib.SetTraceLogLevel(logLevel = raylib.TraceLogLevel.ERROR)
	raylib.SetConfigFlags({raylib.ConfigFlag.MSAA_4X_HINT, raylib.ConfigFlag.VSYNC_HINT})

	screenWidth: i32 = 1920
	screenHeight: i32 = 1080

	raylib.InitWindow(screenWidth, screenHeight, "isometric roguelike");defer raylib.CloseWindow()
	raylib.SetTargetFPS(144)

	num_frames := 6
	currentFrame := 0
	framesCounter := 0
	framesSpeed := 8

	characters := load_textures("assets/characters/male/*.png")
	defer unload_textures(characters)

	textures := load_textures("assets/isometric/*.png")
	defer unload_textures(textures)

	camera := raylib.Camera2D {
		target   = {0, 0},
		rotation = 0,
		zoom     = 1,
	}

	character_position: raylib.Vector2 = {300, 300}

	camera.target = {character_position.x, character_position.y}

	ground_tiles := [?]raylib.Texture2D {
		textures["stone_N.png"],
		textures["stone_S.png"],
		textures["stone_E.png"],
		textures["stone_W.png"],
		textures["stoneSideUneven_N.png"],
		textures["stoneSideUneven_S.png"],
		textures["stoneSideUneven_E.png"],
		textures["stoneSideUneven_W.png"],
	}

	ground_objects := [?]raylib.Texture2D {
		textures["barrels_N.png"],
		textures["barrels_S.png"],
		textures["barrels_E.png"],
		textures["barrels_W.png"],
	}

	character_texture := [?]raylib.Texture2D{characters["Male_0_Idle0.png"]}

	for !raylib.WindowShouldClose() {
		free_all(context.temp_allocator)
		framesCounter += 1

		r := rand.create(1337)
		context.random_generator = rand.default_random_generator(&r)

		handle_input(&camera)

		raylib.BeginDrawing();defer raylib.EndDrawing()
		raylib.ClearBackground(raylib.RAYWHITE)
		raylib.BeginMode2D(camera);defer raylib.EndMode2D()

		for i in 0 ..< i32(1000) {
			x, y := i32(i % 16), i32(i / 16)
			x *= TILE_WIDTH
			if y & 1 == 1 {
				x += TILE_WIDTH / 2
			}
			y *= TILE_HEIGHT / 2
			y -= TILE_FULL_HEIGHT - TILE_HEIGHT

			raylib.DrawTexture(rand.choice(ground_tiles[:]), x, y, raylib.WHITE)
			if rand.int_max(10) == 3 {
				raylib.DrawTexture(rand.choice(ground_objects[:]), x, y, raylib.WHITE)
			}
		}

		raylib.DrawTexture(
			character_texture[0],
			i32(character_position.x),
			i32(character_position.y),
			raylib.WHITE,
		)

		raylib.DrawFPS(i32(camera.target.x), i32(camera.target.y))
	}
}

handle_input :: proc(camera: ^raylib.Camera2D) {
	dt := raylib.GetFrameTime()
	camera_dp: raylib.Vector2
	if raylib.IsKeyPressed(raylib.KeyboardKey.W) {
		camera_dp.y -= 100
	} else if raylib.IsKeyPressed(raylib.KeyboardKey.A) {
		camera_dp.x -= 100
	} else if raylib.IsKeyPressed(raylib.KeyboardKey.S) {
		camera_dp.y += 100
	} else if raylib.IsKeyPressed(raylib.KeyboardKey.D) {
		camera_dp.x += 100
	}
	camera_dp = linalg.normalize0(camera_dp)
	camera.target += camera_dp * dt * 1024
}

load_textures :: proc(path: string) -> map[string]raylib.Texture2D {
	textures := make(map[string]raylib.Texture2D)
	matches, _ := filepath.glob(path)

	for match in matches {
		full := strings.clone(match, context.temp_allocator)
		name := filepath.base(full)
		test := strings.clone_to_cstring(full, context.temp_allocator)
		textures[name] = raylib.LoadTexture(test)
	}

	for match in matches {
		delete(match)
	}
	delete(matches)

	return textures
}

unload_textures :: proc(textures: map[string]raylib.Texture2D) {
	for path, texture in textures {
		delete(path)
		raylib.UnloadTexture(texture)
	}
	delete(textures)
}

