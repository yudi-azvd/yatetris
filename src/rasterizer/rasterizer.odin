#+feature dynamic-literals
package rasterizer

import "core:fmt"
import "core:math"
import "core:mem"

Color :: distinct [4]u8

// Copiado descaradamente de raylib.odin

LIGHTGRAY :: Color{200, 200, 200, 255} // Light Gray
GRAY :: Color{130, 130, 130, 255} // Gray
DARKGRAY :: Color{80, 80, 80, 255} // Dark Gray
YELLOW :: Color{253, 249, 0, 255} // Yellow
GOLD :: Color{255, 203, 0, 255} // Gold
ORANGE :: Color{255, 161, 0, 255} // Orange
PINK :: Color{255, 109, 194, 255} // Pink
RED :: Color{230, 41, 55, 255} // Red
MAROON :: Color{190, 33, 55, 255} // Maroon
GREEN :: Color{0, 228, 48, 255} // Green
LIME :: Color{0, 158, 47, 255} // Lime
DARKGREEN :: Color{0, 117, 44, 255} // Dark Green
SKYBLUE :: Color{102, 191, 255, 255} // Sky Blue
BLUE :: Color{0, 121, 241, 255} // Blue
DARKBLUE :: Color{0, 82, 172, 255} // Dark Blue
PURPLE :: Color{200, 122, 255, 255} // Purple
VIOLET :: Color{135, 60, 190, 255} // Violet
DARKPURPLE :: Color{112, 31, 126, 255} // Dark Purple
BEIGE :: Color{211, 176, 131, 255} // Beige
BROWN :: Color{127, 106, 79, 255} // Brown
DARKBROWN :: Color{76, 63, 47, 255} // Dark Brown
CYAN :: Color{0, 255, 255, 255} // Cyan

WHITE :: Color{255, 255, 255, 255} // White
BLACK :: Color{0, 0, 0, 255} // Black
BLANK :: Color{0, 0, 0, 0} // Blank (Transparent)
MAGENTA :: Color{255, 0, 255, 255} // Magenta
RAYWHITE :: Color{245, 245, 245, 255} // My own White (raylib logo)


Camera :: struct {
	x, y, z: i32,
}

Triangle :: struct {
	p0, p1, p2: Vec2i,
	color:      Color,
}

Vec2i :: [2]i32
Vec3 :: [3]f32
Vec4 :: [4]f32

Rasterizer :: struct {
	image_bytes_count: i32,
	bytes_per_pixel:   i32,
	canvas_width:      i32,
	canvas_height:     i32,
	canvas:            [^]u32,
	viewport_width:    i32,
	viewport_heigth:   i32,
	d:                 i32, // viewport distance to camera
}

// `scale` serve pra multiplicar as dimensões do canvas pra obter
// as dimentsões de `window`.
// É um pouco engessado, mas funciona por agora.
ras_init :: proc(ras: ^Rasterizer, canvas_width, canvas_height: i32) {
	ras.viewport_width = 1 // Pq 1? Pq dá certo?
	ras.viewport_heigth = 1
	ras.d = 1
	ras.bytes_per_pixel = 4
	ras.canvas_width = canvas_width
	ras.canvas_height = canvas_height
	ras.image_bytes_count = canvas_width * canvas_height * ras.bytes_per_pixel
	// Desalocar em ras_deinit:
	ras.canvas = make([^]u32, canvas_width * canvas_height)

	fmt.printfln("ras = %v", ras)
}

ras_deinit :: proc(ras: ^Rasterizer) {}

ras_resize :: proc() {}

draw_begin :: proc(ras: ^Rasterizer) {
	mem.set(ras.canvas, 0, int(ras.image_bytes_count))
}

draw_end :: proc(ras: ^Rasterizer) {
	// TODO: se acabar usando o temp_allocator, posso limpá-lo aqui:
	// free_all(context.temp_allocator)
}

draw_line_v1 :: proc(ras: ^Rasterizer, p0, p1: Vec2i, color: Color) {
	a := f32(p1.y - p0.y) / f32(p1.x - p0.x)
	b := f32(p0.y) - a * f32(p0.x)

	for x := p0.x; x <= p1.x; x += 1 {
		y := _round(a * f32(x) + b) // Truncar? Arredondar pode ser melhor?
		fmt.printfln("y = %v, a = %v", y, a)
		set_pixel(ras, x, y, color)
	}
}

draw_line_v2 :: proc(ras: ^Rasterizer, p0, p1: Vec2i, color: Color) {
	a := f32(p1.y - p0.y) / f32(p1.x - p0.x)

	y := f32(p0.y)
	for x := p0.x; x <= p1.x; x += 1 {
		set_pixel(ras, x, _round(y), color)
		y = y + a
	}
}

// Quando tem que desenhar a linha da direita pra esquerda
// Desenha linhas com x0 > x1
draw_line_v3 :: proc(ras: ^Rasterizer, p0, p1: Vec2i, color: Color) {
	p0, p1 := p0, p1
	if p0.x > p1.x {
		swap(&p0, &p1)
	}

	a := f32(p1.y - p0.y) / f32(p1.x - p0.x)
	y := f32(p0.y)
	for x := p0.x; x <= p1.x; x += 1 {
		set_pixel(ras, x, _round(y), color)
		y = y + a
	}
}

// Mesma coisa que v3, mas invertendo x e y
draw_line_v4 :: proc(ras: ^Rasterizer, p0, p1: Vec2i, color: Color) {
	p0, p1 := p0, p1
	if p0.y > p1.y {
		swap(&p0, &p1)
	}

	a := f32(p1.x - p0.x) / f32(p1.y - p0.y)
	x := f32(p0.x)
	for y := p0.y; y <= p1.y; y += 1 {
		set_pixel(ras, _round(x), y, color)
		x = x + a
	}
}

draw_line_v5 :: proc(ras: ^Rasterizer, p0, p1: Vec2i, color: Color) {
	dx := p1.x - p0.x
	dy := p1.y - p0.y

	if math.abs(dx) > math.abs(dy) {
		// linha está mais para DEITADA
		#force_inline draw_line_v3(ras, p0, p1, color)
	} else {
		//linha está mais para EM PÉ
		#force_inline draw_line_v4(ras, p0, p1, color)
	}
}

// v6: Igual a v5, mas inlined
draw_line :: proc(ras: ^Rasterizer, p0, p1: Vec2i, color: Color) {
	dx := p1.x - p0.x
	dy := p1.y - p0.y
	p0, p1 := p0, p1

	if math.abs(dx) > math.abs(dy) {
		// linha está mais para DEITADA
		if p0.x > p1.x {
			swap(&p0, &p1)
		}

		a := f32(dy) / f32(dx)
		y := f32(p0.y)
		for x := p0.x; x <= p1.x; x += 1 {
			set_pixel(ras, x, _round(y), color)
			y = y + a
		}
	} else {
		// linha está mais para EM PÉ
		if p0.y > p1.y {
			swap(&p0, &p1)
		}

		a := f32(dx) / f32(dy)
		x := f32(p0.x)
		for y := p0.y; y <= p1.y; y += 1 {
			set_pixel(ras, _round(x), y, color)
			x = x + a
		}
	}
}

draw_canvas_border :: proc(ras: ^Rasterizer, color: Color) {
	h := ras.canvas_height
	w := ras.canvas_width
	top_left := Vec2i{-(w + 1) / 2, +(h - 1) / 2}
	top_right := Vec2i{+(w - 1) / 2, +(h - 1) / 2}
	bottom_left := Vec2i{-(w + 1) / 2, -(h + 1) / 2}
	bottom_right := Vec2i{+(w - 1) / 2, -(h + 1) / 2}
	draw_line(ras, top_left, top_right, color)
	draw_line(ras, top_right, bottom_right, color)
	draw_line(ras, bottom_right, bottom_left, color)
	draw_line(ras, bottom_left, top_left, color)
}

// Desenha linhas partindo de `center` com comprimento `radius`
// Equivalente aos raios de uma roda de bicicleta, mas sem a roda.
draw_lines_around_center :: proc(ras: ^Rasterizer, center: Vec2i, radius, initial_angle, angle_step: f32, colors: []Color) {
	alpha: u8 = 255

	assert(len(colors) > 0)

	color_idx := 0
	count := 0
	for angle := initial_angle; angle < math.PI * 2; angle += angle_step {
		x := radius * math.cos_f32(angle)
		y := radius * math.sin_f32(angle)

		p1 := Vec2i{center.x + _round(x), center.y + _round(y)}

		color := colors[color_idx]
		color.a = alpha
		draw_line(ras, center, p1, color)

		color_idx += 1
		if color_idx >= len(colors) {
			color_idx = 0
		}
		count += 1
	}
}

draw_triangle_wf :: proc(ras: ^Rasterizer, p0, p1, p2: Vec2i, c: Color) {
	draw_line(ras, p0, p1, c)
	draw_line(ras, p1, p2, c)
	draw_line(ras, p2, p0, c)
}

// TODO: Os triângulos na main.odin, parecem ter um pixel sobrando embaixo.
// Não sei se é o correto.
draw_triangle_v1 :: proc(ras: ^Rasterizer, p0, p1, p2: Vec2i, c: Color) {
	p0, p1, p2 := p0, p1, p2
	if p1.y < p0.y {
		swap(&p1, &p0)
	}
	if p2.y < p0.y {
		swap(&p2, &p0)
	}
	if p2.y < p1.y {
		swap(&p2, &p1)
	}
	assert(p0.y <= p1.y && p1.y <= p2.y)

	// TODO: Não alocar diretamente. Usar pool ou
	// usar o temp_allocator
	x01 := interpolate(p0.y, f32(p0.x), p1.y, f32(p1.x))
	x12 := interpolate(p1.y, f32(p1.x), p2.y, f32(p2.x))
	x02 := interpolate(p0.y, f32(p0.x), p2.y, f32(p2.x))

	unordered_remove(&x01, len(x01) - 1)
	// TODO: Não alocar diretamente. Usar pool ou
	// usar o temp_allocator
	x012 := concatenate(x01, x12)

	mid := len(x012) / 2
	x_left: []f32
	x_right: []f32
	if x02[mid] < x012[mid] {
		x_left = x02[:]
		x_right = x012[:]
	} else {
		x_left = x012[:]
		x_right = x02[:]
	}

	for y := p0.y; y < p2.y - 1; y += 1 {
		y_idx := y - p0.y
		for x := x_left[y_idx]; x <= x_right[y_idx]; x += 1 {
			set_pixel(ras, _round(x), y, c)
		}
	}

	delete_dynamic_array(x01)
	delete_dynamic_array(x12)
	delete_dynamic_array(x02)
	delete_dynamic_array(x012)
}

@(private)
concatenate :: proc(a, b: [dynamic]f32) -> [dynamic]f32 {
	greatest := max(len(a), len(b))
	result := make([dynamic]f32)
	idx := 0
	for v in a {
		append(&result, v)
	}
	for v in b {
		append(&result, v)
	}
	assert(len(a) + len(b) == len(result))
	return result
}


/*	
	```
	P0		    
	*-----------*
	|           |
	|           |
	*-----------*
				P1
	```
	Só funciona desenhar de cima para baixo
*/
draw_rectangle_temp :: proc(ras: ^Rasterizer, p0, p1: Vec2i, color: Color) {
	start_y := p0.y
	end_y := p1.y
	pl := Vec2i{p0.x, p0.y}
	pr := Vec2i{p1.x, p0.y}
	for y := start_y; y <= end_y; y += 1 {
		pl.y += 1
		pr.y += 1
		draw_line(ras, pl, pr, color)
	}
}

to_number :: #force_inline proc(c: Color) -> u32 {
	n: u32 = 0
	n += u32(c.a) << (8 * 3)
	n += u32(c.b) << (8 * 2)
	n += u32(c.g) << (8 * 1)
	n += u32(c.r) << (8 * 0)
	return n
}

/*
Assume que x e y estão no espaço do canvas

x = [-Cw/2, Cw/2);
y = [-Ch/2, Ch/2)
*/
set_pixel :: #force_inline proc(ras: ^Rasterizer, x, y: i32, color: Color) {
	x := (ras.canvas_width / 2) + x
	y := (ras.canvas_height / 2) - y - 1

	if !(0 <= x && x < ras.canvas_width) {
		return
	}
	if !(0 <= y && y < ras.canvas_height) {
		return
	}

	idx := x + ras.canvas_width * y
	ras.canvas[idx] = to_number(color)
}

/*
d = f(i). Calcula e retorna os valores entre os pontos (i0,d0) e (i1,d1)

Assume i1 > i0

i0 e i1 variáveis independentes

d0 e d1 variáveis dependentes
*/
interpolate :: proc(i0: i32, d0: f32, i1: i32, d1: f32) -> [dynamic]f32 {
	values := make([dynamic]f32, context.allocator)
	append(&values, d0)
	// values: [dynamic]f32 = {d0}
	d := d0

	if i0 == i1 {
		return values
	}

	a := (d1 - d0) / f32(i1 - i0)
	for i := i0; i <= i1; i += 1 {
		append(&values, d)
		d += a
	}

	return values
}

magnitude :: proc(v: Vec2i) -> f32 {
	n1 := v.x * v.x + v.y * v.y
	n2 := math.sqrt_f32(f32(n1))
	return n2
}

swap :: #force_inline proc(a, b: ^Vec2i) {
	t := a^
	a^ = b^
	b^ = t
}


/*
x e y agora são f32 porque são coordenadas do Viewport, que está no espaço
de coordenadas do cena (world space) e não no canvas space.
*/
viewport_to_canvas :: proc(using ras: ^Rasterizer, x, y: f32) -> Vec2i {
	width_ratio := f32(canvas_width - 1) / f32(viewport_width)
	height_ratio := f32(canvas_height - 1) / f32(viewport_heigth)
	c := Vec2i{_round(x * width_ratio), _round(y * height_ratio)}
	return c
}

/*
Converte de world space -> viewport space -> canvas space
*/
project_vertex :: proc(ras: ^Rasterizer, v: Vec3) -> Vec2i {
	d := f32(ras.d)
	return viewport_to_canvas(ras, v.x * d / v.z, v.y * d / v.z)
}


Mesh :: struct {
	vertices:  [dynamic]Vec3,
	triangles: [dynamic][3]i32, // Índices dos pontos dos triângulos em `vertices`
}

Transf :: struct {
	translation: Vec3,
	rotation:    f32,
	scale:       f32,
}

Transform :: [4][4]f32

Model :: struct {
	mesh:      Mesh,
	transf:    Transf,
	transform: Transform,
}

model_from_mesh :: proc(mesh: Mesh) -> Model {
	m := Model{}
	m.mesh = mesh
	m.transf.scale = 1
	m.transf.rotation = 0
	m.transf.translation = Vec3{}

	t := m.transform.x
	return m
}

gen_mesh_cube :: proc(size: f32) -> Mesh {
	m := Mesh{}
	append(&m.vertices, Vec3{+size, +size, +size})
	append(&m.vertices, Vec3{-size, +size, +size})
	append(&m.vertices, Vec3{-size, -size, +size})
	append(&m.vertices, Vec3{+size, -size, +size})
	append(&m.vertices, Vec3{+size, +size, -size})
	append(&m.vertices, Vec3{-size, +size, -size})
	append(&m.vertices, Vec3{-size, -size, -size})
	append(&m.vertices, Vec3{+size, -size, -size})

	append(&m.triangles, [?]i32{0, 1, 2})
	append(&m.triangles, [?]i32{0, 2, 3})
	append(&m.triangles, [?]i32{4, 0, 3})
	append(&m.triangles, [?]i32{4, 3, 7})
	append(&m.triangles, [?]i32{5, 4, 7})
	append(&m.triangles, [?]i32{5, 7, 6})
	append(&m.triangles, [?]i32{1, 5, 6})
	append(&m.triangles, [?]i32{1, 6, 2})
	append(&m.triangles, [?]i32{4, 5, 1})
	append(&m.triangles, [?]i32{4, 1, 0})
	append(&m.triangles, [?]i32{2, 6, 7})
	append(&m.triangles, [?]i32{2, 7, 3})

	return m
}

draw_mesh :: proc(ras: ^Rasterizer, mesh: Mesh, pos: Vec3, c: Color) {
	// TODO: Não alocar, usar uma pool ou sei lá
	// Ou usar o temp_allocator
	projected := make([dynamic]Vec2i)
	for v in mesh.vertices {
		append(&projected, project_vertex(ras, v + pos))
	}
	for tri in mesh.triangles {
		draw_triangle_wf(
			ras,
			projected[tri[0]], //
			projected[tri[1]], //
			projected[tri[2]], //
			c,
		)
	}
	delete_dynamic_array(projected)
}

draw_model :: proc(ras: ^Rasterizer, model: Model, pos: Vec3, c: Color) {
	model := model
	model.transf.translation = pos
	// TODO:  Não alocar, usar uma pool ou sei lá
	// Ou usar o temp_allocator
	projected: [dynamic]Vec2i
	for v in model.mesh.vertices {
		v := apply_transform(v, model.transf)
		append(&projected, project_vertex(ras, v))
	}
	for tri in model.mesh.triangles {
		draw_triangle_wf(
			ras,
			projected[tri[0]], //
			projected[tri[1]], //
			projected[tri[2]], //
			c,
		)
	}
	delete_dynamic_array(projected)
}

apply_transform :: proc(vertex: Vec3, transf: Transf) -> Vec3 {
	v := vertex
	v *= transf.scale // FIXME: não altera o tamanho visualmente, mas a velocidade de movimento muda perceptivelmente
	v += transf.rotation
	v += transf.translation
	return v
}

@(private)
_round :: proc(v: f32) -> i32 {
	return i32(math.round_f32(v))
}
