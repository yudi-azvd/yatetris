package rasterizer

import "core:fmt"
import "core:math"

import rl "vendor:raylib"

Line :: struct {
	p0, p1: Vec2i,
	color:  Color,
}

Raylib_App :: struct {
	window_height: i32,
	window_width:  i32,
	scale:         f32,
	title:         cstring,
}

main :: proc() {
	canvas_width :: 600
	canvas_height :: 600

	app := Raylib_App{}
	app.window_width = 600
	app.window_height = 600
	app.title = "Rasterizer"
	app.scale = f32(app.window_height) / f32(canvas_height)
	fmt.printfln("scale = %v", app.scale)

	ras := Rasterizer{}
	ras_init(&ras, canvas_width, canvas_height)
	defer ras_deinit(&ras)

	rl.InitWindow(app.window_width, app.window_height, app.title)
	defer rl.CloseWindow()

	// ras.image = rl.LoadImage("/home/yudi/Pictures/skan-thumbnail.png")
	image := rl.Image{}
	image.mipmaps = 1
	image.width = ras.canvas_width
	image.height = ras.canvas_height
	image.format = .UNCOMPRESSED_R8G8B8A8
	// TODO: defer delete(image.data) ou algo assim
	image.data = make([^]u8, ras.image_bytes_count)

	texture := rl.LoadTextureFromImage(image)
	defer rl.UnloadTexture(texture)

	// Coordenadas do espaço do canvas
	tri1 := []Triangle { 	//
		Triangle{Vec2i{50, 50}, Vec2i{80, 90}, Vec2i{30, 40}, YELLOW},
		Triangle{Vec2i{100, 50}, Vec2i{110, 90}, Vec2i{150, 40}, MAGENTA},
		Triangle{Vec2i{100, 90}, Vec2i{90, 100}, Vec2i{120, 100}, PURPLE},
		Triangle{Vec2i{-20, -25}, Vec2i{20, 5}, Vec2i{20, 25}, BLUE},
	}
	tri2 := []Triangle { 	//https://haqr.eu/tinyrenderer/rasterization/
		Triangle{Vec2i{7, 45}, Vec2i{35, 100}, Vec2i{45, 60}, RED},
		Triangle{Vec2i{120, 35}, Vec2i{90, 5}, Vec2i{45, 110}, WHITE},
		Triangle{Vec2i{115, 83}, Vec2i{80, 90}, Vec2i{85, 120}, GREEN},
	}
	trans1 := Vec2i{-200, 100}
	for &t in tri1 {
		t.p0 += trans1
		t.p1 += trans1
		t.p2 += trans1
	}
	trans2 := Vec2i{-200, -250}
	for &t in tri2 {
		t.p0 += trans2
		t.p1 += trans2
		t.p2 += trans2
	}

	// The four "front" vertices
	vaf := [?]f32{-2.0, -0.5, 5}
	vbf := [?]f32{-2.0, +0.5, 5}
	vcf := [?]f32{-1.0, +0.5, 5}
	vdf := [?]f32{-1.0, -0.5, 5}
	// The four "back" vertices
	vab := [?]f32{-2.0, -0.5, 6}
	vbb := [?]f32{-2.0, +0.5, 6}
	vcb := [?]f32{-1.0, +0.5, 6}
	vdb := [?]f32{-1.0, -0.5, 6}


	cube1 := gen_mesh_cube(1)
	pos1 := Vec3{}
	{
		for &v in cube1.vertices {
			// v += Vec3{+1.5, 0, 7}
		}
	}
	model1 := model_from_mesh(cube1)
	model1.transf.scale = 0.5
	cube2 := gen_mesh_cube(1.2)
	pos2 := Vec3{}
	{
		for &v in cube2.vertices {
			v += Vec3{+1.5, 0, 7}
		}
	}
	model2 := model_from_mesh(cube2)
	model2.transf.scale = 4

	rl.SetTargetFPS(30)
	for !rl.WindowShouldClose() {
		rl.PollInputEvents()

		if rl.IsKeyDown(.F11) {
			fmt.printfln("Toggle Fullscreen")
			// TODO: No meu PC (Ubuntu 18), quando o toggle fica habilitado
			// trava a tela e não responde mais
			// rl.ToggleFullscreen()
			app.window_width = rl.GetScreenWidth()
			app.window_height = rl.GetScreenHeight()
			app.scale = f32(app.window_height) / f32(ras.canvas_height)
		}

		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)
		draw_begin(&ras)
		{
			draw_lines_around_center(&ras, Vec2i{0, 0} + Vec2i{150, -100}, 45, 0, math.PI / 24, colors)

			for t in tri1 {
				// draw_triangle_wf(&ras, t.p0, t.p1, t.p2, WHITE)
				c := t.color
				c.a = 200
				draw_triangle_v1(&ras, t.p0, t.p1, t.p2, c)
			}
			for t in tri2 {
				// draw_triangle_wf(&ras, t.p0, t.p1, t.p2, WHITE)
				draw_triangle_v1(&ras, t.p0, t.p1, t.p2, t.color)
			}

			draw_rectangle_temp(&ras, Vec2i{-1, -1}, Vec2i{1, 1}, WHITE)
			draw_text(&ras, "test string", 100, 100, 12, PINK)
			rl.DrawText("Text", 100, 100, 12, rl.WHITE)

			// The back face
			draw_line(&ras, project_vertex(&ras, vab), project_vertex(&ras, vbb), RED)
			draw_line(&ras, project_vertex(&ras, vbb), project_vertex(&ras, vcb), RED)
			draw_line(&ras, project_vertex(&ras, vcb), project_vertex(&ras, vdb), RED)
			draw_line(&ras, project_vertex(&ras, vdb), project_vertex(&ras, vab), RED)
			// The front-to-back edges
			draw_line(&ras, project_vertex(&ras, vaf), project_vertex(&ras, vab), GREEN)
			draw_line(&ras, project_vertex(&ras, vbf), project_vertex(&ras, vbb), GREEN)
			draw_line(&ras, project_vertex(&ras, vcf), project_vertex(&ras, vcb), GREEN)
			draw_line(&ras, project_vertex(&ras, vdf), project_vertex(&ras, vdb), GREEN)
			// The front face
			draw_line(&ras, project_vertex(&ras, vaf), project_vertex(&ras, vbf), BLUE)
			draw_line(&ras, project_vertex(&ras, vbf), project_vertex(&ras, vcf), BLUE)
			draw_line(&ras, project_vertex(&ras, vcf), project_vertex(&ras, vdf), BLUE)
			draw_line(&ras, project_vertex(&ras, vdf), project_vertex(&ras, vaf), BLUE)

			pos1 += Vec3{0, 0.01, 0.01}
			pos2 += Vec3{-.012, -0.01, 0.01}
			draw_model(&ras, model1, pos1, ORANGE)
			draw_model(&ras, model2, pos2, GREEN)
			draw_canvas_border(&ras, YELLOW)
		}
		draw_end(&ras)
		rl.UpdateTexture(texture, ras.canvas)
		rl.DrawTextureEx(texture, rl.Vector2{0, 0}, 0, app.scale, rl.WHITE)
		rl.EndDrawing()
	}
}
