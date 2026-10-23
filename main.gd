extends Node2D

const MAP_WIDTH = 10
const MAP_HEIGHT = 6

const TILE_WIDTH = 64
const TILE_HEIGHT = 32

const MAP_ORIGIN = Vector2(480,75)

var hovered_cell = Vector2i(-1,-1)
var selected_cell = Vector2i(-1,-1)
var unit_cell = Vector2i(3,2)
var unit_selected = false

func _draw() -> void:
	draw_battlefield()
	draw_selected_tile()
	draw_hovered_tile()
	draw_unit(unit_cell)
	draw_selected_unit()

func grid_to_screen(cell: Vector2i) -> Vector2:
	var screen_x = (cell.x - cell.y) * TILE_WIDTH / 2.0
	var screen_y = (cell.x + cell.y) * TILE_HEIGHT / 2.0
	return MAP_ORIGIN + Vector2(screen_x, screen_y)

func screen_to_grid(mouse_pos: Vector2) ->Vector2i:
	var local_pos = mouse_pos - MAP_ORIGIN
	
	var u = local_pos.x / (TILE_WIDTH / 2)
	var v = local_pos.y / (TILE_HEIGHT / 2)
	
	var grid_x = (u + v) / 2.0
	var grid_y = (v - u) / 2.0
	
	return Vector2i(
		roundi(grid_x),
		roundi(grid_y)
	)

func draw_tile(
	center: Vector2,
	fill_color: Color,
	outline_color: Color,
	outline_width: float = 1.0
):
	var points = PackedVector2Array([
		center + Vector2(0, -TILE_HEIGHT/2.0),
		center + Vector2(TILE_WIDTH/2.0, 0),
		center + Vector2(0, TILE_HEIGHT/2.0),
		center + Vector2(-TILE_WIDTH/2.0, 0)
	])
	
	draw_colored_polygon(points,fill_color)
	
	var outline = PackedVector2Array([
		points[0],
		points[1],
		points[2],
		points[3],
		points[0]
	])
	
	draw_polyline(
		outline, outline_color, outline_width, true
	)

func draw_battlefield():
	for y in range(MAP_HEIGHT):
		for x in range(MAP_WIDTH):
			var center = grid_to_screen(Vector2i(x,y))
			
			var tile_color = Color("#668f50")
			
			if (x + y) % 2 == 0:
				tile_color = Color("#729c59")
			
			draw_tile(center, tile_color, Color("#405d38"))

func draw_unit(cell: Vector2i):
	var center = grid_to_screen(cell)
	
	#sombra da unidade
	draw_circle(
		center + Vector2(0,7),
		9,
		Color("#344b30")
	)
	
	# Corpo da unidade
	var body = PackedVector2Array([
		center + Vector2(-7, 1),
		center + Vector2(7, 1),
		center + Vector2(5, -12),
		center + Vector2(-5, -12)
		])
	
	draw_colored_polygon(body, Color("#365fb8"))
	# Cabeça
	draw_circle(
		center + Vector2(0, -17),
		5,
		Color("#e8bd91")
		)

func _process(_delta: float) -> void:
	var mouse_pos = get_local_mouse_position()
	var cell = screen_to_grid(mouse_pos)
	
	if cell.x >= 0 and cell.x < MAP_WIDTH and cell.y >= 0 and cell.y < MAP_HEIGHT:
		hovered_cell = cell
	else:
		hovered_cell = Vector2i(-1, -1)
	
	queue_redraw()

func draw_hovered_tile():
	if hovered_cell.x < 0:
		return
	
	var center = grid_to_screen(hovered_cell)
	
	draw_tile(
		center,
		Color(1.0, 0.85, 0.2, 0.45),
		Color("#fff2a0"),
		2.0)

func draw_selected_tile():
	if selected_cell.x < 0:
		return
	
	var center = grid_to_screen(selected_cell)
	
	draw_tile(
		center,
		Color(0.2, 0.5, 1.0, 0.45),
		Color("#9cc9ff"),
		2.0
	)

func draw_selected_unit():
	if not unit_selected:
		return
	
	var center = grid_to_screen(unit_cell)
	
	draw_arc(
		center + Vector2(0,2),
		14.0,
		0.0,
		TAU,
		32,
		Color("#8de5ff"),
		2.0,
		true
	)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var mouse_pos = get_local_mouse_position()
			var cell = screen_to_grid(mouse_pos)
			
			if cell.x >= 0 and cell.x < MAP_WIDTH and cell.y >= 0 and cell.y < MAP_HEIGHT:
				selected_cell = cell
				
				if cell == unit_cell:
					unit_selected = true
				else:
					unit_selected = false
					
				queue_redraw()
